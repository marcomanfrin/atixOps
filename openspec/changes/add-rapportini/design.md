## Context

AtixOps already has a report-shaped object: `WorkReport` (`entities/WorkReport.java:19-24`) is `@OneToOne` with `Work` behind a unique constraint on `work_id`, and owns `WorkReportEntry` rows (`description`, `hours`, `date`, `createdBy`). It is exposed through `WorkReportsController` (`/work-reports`), `WorkReportService`, `hooks/api/useWorkReports.ts`, and a section of `WorkDetailPage.tsx`. In practice it is a **mutable hours ledger per work order**.

The rapportino validated in `prototypes/index.html` is a different object: it carries a report number (`N° Rapporto`), an intervention date, intervention-type flags, a checklist, materials, and a customer signature. A technician performs several site visits per work order, and each visit produces its own signed document. The prototype's storage and auth (Firebase, PIN login, client-side expiry check at `prototypes/index.html:1439`) are throwaway; only its field set and UX flow carry over.

Four properties of the current codebase constrain the design:

1. **No migration tool.** `application.properties:22` sets `spring.jpa.hibernate.ddl-auto = update`. There is no Flyway or Liquibase. Schema changes are applied by Hibernate with no review step and no rollback.
2. **Attachments are MinIO-backed.** `AttachmentService.java:69-78` uploads to MinIO and stores `minio.public-url + "/" + bucket + "/" + objectKey` as the attachment URL. Whether that bucket is publicly readable is not determinable from the repository.
3. **Almost nothing is public.** `SecurityConfig.java:40-41` permits only `/auth/**` and `/health`.
4. **`AttachmentTargetType.REPORT` already exists** and is unused, alongside `AttachmentType.PDF` — the polymorphic attachment system was built anticipating exactly this.

## Goals / Non-Goals

**Goals:**

- Model an intervention-level signed document without disturbing `WorkReport`, `WorkReportService`, `WorkReportsController`, or the existing `WorkDetailPage` hours section.
- Guarantee that a signed rapportino can never change, including when the referenced client, plant or work order is later edited.
- Support both on-site and remote signature through a single server-side document pipeline.
- Keep all schema work additive, so `ddl-auto = update` cannot perform a destructive operation.
- Keep hours a single source of truth: `WorkReport.totalHours` stays authoritative for the work order.
- Ship a usable increment (on-site signature) before the higher-risk remote-signature surface.

**Non-Goals:**

- Replacing or absorbing `WorkReport`.
- Introducing Flyway or Liquibase (separate change).
- Emailing PDFs, admin CRUD for the checklist template, standalone rapportini without a work order, or a materials catalogue.
- Offline/PWA capture. The technician is assumed online when saving.

## Decisions

### D1 — New `Rapportino` entity as a child of `Work`, not an extension of `WorkReport`

`Rapportino` is a new entity with `work_id` `NOT NULL` in a `1:N` relation from `Work`.

*Rationale.* `WorkReport` is `1:1` with `Work`. Extending it would cap the system at one rapportino per work order, which contradicts the domain (multiple site visits per order). It would also mix a mutable ledger with an immutable signed document: editing a `WorkReportEntry` would silently contradict a PDF the customer already signed. Finally, extending it means `ALTER`s on two live tables under `ddl-auto` (constraint 1), whereas a new entity adds only new tables.

*Alternatives considered.*

- **Extend `WorkReport`/`WorkReportEntry` with checklist, materials, signature, PDF fields.** Rejected: wrong cardinality, mutability conflict, `ALTER`s on live tables, and `totalHours` would become ambiguous between "hours worked" and "hours on the signed report".
- **Fully parallel model, unlinked from `Work`** (free-text client and plant, as the prototype does). Rejected as the default: client and plant data would be re-keyed by hand, hours could not be reconciled with the work order, and the two models would drift. Revisit only if standalone call-outs become a requirement.

### D2 — Signed hours project into `WorkReport` as a read-only `WorkReportEntry`

On transition to `SIGNED`, the service resolves (or creates, as `WorkReportService` already does) the `WorkReport` for the work and appends one `WorkReportEntry` with `description` = intervention description, `hours` = ordinary + overtime, `date` = intervention date, `createdBy` = technician. `WorkReportEntry` gains a nullable `rapportino_id` FK; entries carrying it are rendered read-only and rejected by the existing update and delete endpoints.

*Rationale.* Existing consumers (`totalHours`, `WorkDetailPage`, `useWorkReports.ts`) keep working untouched, and the technician enters hours once. The FK is the minimum coupling that lets the ledger protect rapportino-derived rows.

*Alternatives considered.* Keeping the two registers fully separate — rejected because it forces double entry and lets the two hour totals disagree. Projecting only ordinary hours — rejected on the user's decision; overtime is real work on the order.

Travel km, meal and parking are **not** projected: they are not hours, and `WorkReportEntry` has nowhere to put them. They stay on the rapportino for billing.

### D3 — Immutable denormalised snapshot on the rapportino

`client_name`, `client_reference`, `plant_label` and `order_number` are copied onto the rapportino at creation and frozen at signature.

*Rationale.* A countersigned document must render identically forever. Resolving these through FKs at read time means renaming a client retroactively rewrites signed documents.

*Alternative considered.* Rely on the PDF alone as the frozen artefact and keep the entity fully normalised. Rejected: the detail page, the list and the public signing preview all render from the entity, so they would drift from the PDF.

### D4 — Status machine with hard immutability after signature

```
DRAFT ──sign─────────────▶ SIGNED ──void──▶ VOID
  │                          ▲
  └─request signature──▶ AWAITING_SIGNATURE
                             │
                     expired / revoked
                             ▼
                           DRAFT
```

`DRAFT` is freely editable. `AWAITING_SIGNATURE` is content-frozen (the customer is looking at a preview) but can fall back to `DRAFT` when the token expires or is revoked. `SIGNED` rejects every mutation with `409`. Corrections go through `VOID` plus a new rapportino that references the voided one.

*Rationale.* Any edit-after-signature path invalidates the signature's meaning. Void-and-reissue is the standard accounting-document pattern and leaves an audit trail.

### D5 — Checklist template in the database, with a label snapshot on every answer

`checklist_template_items` (`code` unique, `label_it`, `label_en`, `position`, `active`) is seeded at bootstrap with the six items from `prototypes/index.html:814-821`, using the same idempotent-guard pattern as the default admin user. Each `rapportino_checklist_answers` row stores `template_item_id` (nullable) **and** `label_snapshot`.

*Rationale.* The label snapshot is what actually matters: it decouples historical documents from the template, so editing or deactivating an item never rewrites past reports. Given that, a table costs little more than an enum and removes the need for a deployment to change an activity item.

*Alternative considered.* Hardcoded enum or config list. Rejected: every wording change needs a deploy, and without the snapshot, historical answers lose their meaning. Admin CRUD over the template is deliberately deferred — seeded rows only in this change.

### D6 — Signature stored in a separate lazy table; PDF stored as a `REPORT` attachment

The signature image (PNG data URL from the canvas) goes into `rapportino_signatures`, a lazy `1:1` side table, never serialised in list responses. The generated PDF goes through `attachmentService.uploadAndLink(file, AttachmentTargetType.REPORT, rapportinoId)`.

*Rationale.* The signature is small, always needed together with the document, and never needed in a list — a side table keeps list payloads clean without the ceremony of an upload round-trip. The PDF is a file and belongs in the file system that already exists for it; `REPORT` was reserved for precisely this.

*Alternatives considered.* Signature as a MinIO attachment — rejected: it produces a directly addressable URL for a biometric-adjacent personal datum (constraint 2), and needs an upload before the record is even valid. Signature inline on the `rapportini` row — rejected: it would ride along in every list response.

### D7 — Server-side PDF generation

PDF rendering happens in `RapportinoPdfService` from a server-side HTML template, using an HTML-to-PDF renderer added to `pom.xml`.

*Rationale.* In the remote-signature flow the technician's browser is not present when the document becomes final, so a client-side generator cannot produce the authoritative artefact. One renderer also means one layout definition and byte-reproducible output; the service stores a SHA-256 of the generated bytes for integrity checking.

*Alternative considered.* jsPDF in the browser, as the prototype does. Rejected: it cannot serve the remote flow, and keeping it for the on-site flow only would mean maintaining the layout twice.

### D8 — PDF served through an authenticated endpoint, never a raw storage URL

`GET /rapportini/{id}/pdf` streams (or issues a short-lived presigned URL for) the document after the same authorization check as the detail endpoint. The raw `attachment.url` is not surfaced in rapportino responses.

*Rationale.* This is correct whether or not the MinIO bucket is public, so the design does not depend on an unverified fact. Verifying the bucket's ACL remains a blocking task before the first PDF is generated (see Risks).

### D9 — Public signing surface: hashed, single-use, server-expiring tokens

`rapportino_signature_requests` holds `token_hash` (SHA-256 of a 256-bit `SecureRandom` token), `expires_at`, `used_at`, `revoked_at`, `created_by_id`, plus `signer_ip` and `signer_user_agent` for audit. The plaintext token exists only in the URL handed to the technician.

- `GET /public/rapportini/sign/{token}` returns a minimal read-only preview.
- `POST /public/rapportini/sign/{token}` accepts signer name, signature image and privacy consent, then drives the same signature transition as the on-site path.
- `SecurityConfig` gains exactly one matcher: `/public/**`.
- Expiry, single use and revocation are enforced server-side on every call. Expired, unknown, used and revoked tokens return an identical response so the endpoint cannot be probed. Requests are rate-limited per IP.
- The preview exposes only what the customer must see to sign: number, date, client name, description, checklist, materials and totals. No internal identifiers, no other work orders, no other documents.

*Rationale.* The token is a bearer credential, so it is stored hashed like a password. The prototype's client-side expiry check is not a control at all.

*Alternatives considered.* Reusing the JWT infrastructure with a scoped short-lived token — rejected: it puts a token the auth filter recognises into a URL sent over email/WhatsApp, widening the blast radius of a leak. OTP by SMS/email to the customer — rejected as scope creep; the technician hands over the link in person or through a channel they already use.

### D10 — Report numbering

`RapportinoNumberGenerator` issues `RFL-{year}-{seq}` with a per-year sequence, assigned at creation and unique. Concurrency is handled with a dedicated counter row under a pessimistic lock (or a Postgres sequence per year), never by reading `MAX()`.

*Rationale.* Two technicians creating a rapportino simultaneously must not collide. Assigning at creation rather than at signature keeps the number stable in the UI while the technician works.

### D11 — Both a dedicated page and an entry point inside `WorkDetailPage`

`/reports` (filtered list), `/reports/:id` (detail, PDF, actions), `/reports/:id/edit` (wizard, `DRAFT` only), plus a rapportini card in `WorkDetailPage` that opens the same wizard with `workId` prefilled.

*Rationale.* These are two different jobs: "show me my reports" is a technician's daily entry point, "what happened on this work order" is the work-order view. Building only one forces the other workflow through the wrong door.

The wizard is four steps — Data → Activities + Materials → Hours/Travel → Signature — because the technician fills it on a phone in the field, where a single long form is unusable.

### D12 — Sidebar placement and role scoping

A `Rapportini` entry in `mainNavItems`, after `works`, with no `adminOnly` flag. Visibility filtering happens in `RapportinoService`: `TECHNICIAN`/`USER` see rapportini where they are the technician or the creator; `ADMIN`, `OWNER` and `ADMINISTRATION` see all and may void.

*Rationale.* Rapportini are daily operational work, not management reporting, so they belong beside works and tickets. Hiding a sidebar entry is presentation, not authorization — the filter that matters is the one in the service.

### D13 — Additive-only schema under `ddl-auto = update`

Six new tables plus one nullable column on `work_report_entries`. No column is dropped, renamed or retyped.

*Rationale.* Under `ddl-auto = update` Hibernate applies changes unreviewed. Constraining the change to purely additive operations makes the worst case "a table or column that should not exist", never data loss. Adopting Flyway first would be better engineering but blocks this feature behind a risky baseline against a populated production database, so it is a separate change.

## Risks / Trade-offs

- **Public signing endpoint is the largest new attack surface** → single narrow matcher (`/public/**`), hashed single-use tokens, server-side expiry, uniform responses for all invalid-token cases, per-IP rate limiting, and a minimal response body. Reviewed as its own step, after the authenticated flow already works.
- **Signed PDFs and signature images are personal data, and MinIO URLs may be publicly readable** (`AttachmentService.java:78`) → bucket ACL verification is a blocking task before the first PDF is generated; the PDF is served only through an authenticated endpoint (D8) regardless of the outcome.
- **`ddl-auto = update` applies schema changes with no review or rollback** → additive-only design (D13); schema inspected on a staging database before production deploy; no destructive operation is expressible.
- **The nullable `rapportino_id` on `work_report_entries` is the one touch to a live table** → nullable with no default and no backfill; existing rows and existing queries are unaffected; only new code reads it.
- **Hours projection can double-count if signature is retried or a void is mishandled** → the projection is idempotent on `rapportino_id`, runs inside the signature transaction, and voiding removes or zeroes the generated entry.
- **A new PDF dependency in a Spring Boot 4 / Java 21 project may not have a clean version** → renderer selection and a smoke render are part of the PDF step; if none integrates cleanly, the fallback is a plain-layout renderer, not a client-side generator (which would break the remote flow).
- **Frozen snapshot means a typo in the client name survives into signed documents** → intended: correction is void-and-reissue (D4).
- **Canvas signature quality varies across devices** (touch, stylus, high-DPI) → `SignaturePad` handles pointer events with DPI scaling and offers undo/clear; validated on a real tablet before the remote flow is built.
- **The public frontend page must render with no `AuthContext`** → `PublicSignPage` sits outside `ProtectedRoute` and uses a separate API client that does not attach the JWT; a leak here would send the technician's token to an unauthenticated route.

## Migration Plan

No data migration: the feature adds tables and creates no rows for existing entities. Rollout is sequenced so each stage is independently useful and the risky surface comes last.

1. Enums, entities, repositories — no runtime behaviour change.
2. DTOs, `RapportinoService`, state machine, number generator.
3. `RapportiniController` (authenticated only) with role scoping — testable end-to-end via Postman.
4. **Blocking:** verify the MinIO bucket ACL. Then PDF generation and `REPORT` attachment linking, plus the authenticated PDF endpoint.
5. On-site signature endpoint and the hours projection into `WorkReport`. **Backend is shippable here**: signed rapportini with PDFs, no public surface.
6. Signature-request tokens, public endpoints, `SecurityConfig` matcher — reviewed independently.
7. Frontend API client, hook, list and detail pages.
8. Wizard and `SignaturePad`.
9. Public `/sign/:token` page.
10. Sidebar, i18n, `WorkDetailPage` card.

**Rollback.** Before step 6, rollback is a code revert: the new tables are orphaned but harmless, and no existing behaviour was modified. After step 6, rollback additionally means removing the `/public/**` matcher — the highest-value single revert. `WorkReportEntry` rows already generated survive a revert as ordinary entries, since `rapportino_id` is nullable and unread by the old code.

## Open Questions

- **Is the `atix-attachments` MinIO bucket public-read?** Blocking before step 4. Determines whether the PDF endpoint streams bytes or issues presigned URLs.
- **Does the report sequence reset each January, and is it global or per technician?** Assumed global and yearly (`RFL-2026-0001`) until contradicted.
- **How long are signature images retained under GDPR?** Consent timestamp is recorded; no automatic deletion is implemented in this change. A retention policy may require a follow-up.
- **Default expiry for a remote signature link?** The prototype offers 15 / 60 / 1440 minutes. Assumed selectable by the technician with a 60-minute default and a server-enforced maximum.
- **Should a `VOID` rapportino remain visible to technicians, or only to admins?** Assumed visible with a clear badge, since hiding it invites re-signing a duplicate.
- **Can a work order be closed while a rapportino is still `DRAFT` or `AWAITING_SIGNATURE`?** No interaction with `WorkStateMachine` is specified in this change; assumed independent for now.
