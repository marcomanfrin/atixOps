## 0. Blocking investigation

- [x] 0.1 Determine whether the `atix-attachments` MinIO bucket is public-read (check the bucket policy on the running instance, then try fetching an existing attachment URL with no credentials) and record the answer in `design.md` Open Questions
- [x] 0.2 Based on 0.1, decide whether `GET /rapportini/{id}/pdf` streams bytes through the backend or issues a short-lived presigned URL, and note the decision in `design.md`

## 1. Backend domain model

- [x] 1.1 Add enums `RapportinoStatus` (DRAFT, AWAITING_SIGNATURE, SIGNED, VOID), `RapportinoWorkState` (IN_PROGRESS, COMPLETED), `SignatureSource` (LOCAL, REMOTE) in `enums/`
- [x] 1.2 Add `entities/Rapportino` — work FK (not null), number, status, intervention date, technician, four intervention-type flags, description, work/travel hours, travel km, meal, parking, work state, snapshot fields (client name, client reference, plant label, order number), signer name, signed at, privacy accepted at, signature source, pdf attachment id, pdf hash, voided at/by, created by, timestamps
- [x] 1.3 Add `entities/ChecklistTemplateItem` (code unique, label_it, label_en, position, active)
- [x] 1.4 Add `entities/RapportinoChecklistAnswer` (rapportino FK, template item FK nullable, label snapshot, checked, note, position)
- [x] 1.5 Add `entities/RapportinoMaterial` (rapportino FK, description, quantity, position)
- [x] 1.6 Add `entities/RapportinoSignature` — lazy one-to-one with rapportino, signature image, captured at, signer IP, signer user agent
- [x] 1.7 Add `entities/RapportinoSignatureRequest` (rapportino FK, token hash unique, expires at, used at, revoked at, created by, signer IP, signer user agent)
- [x] 1.8 Add nullable `rapportino_id` FK to `entities/WorkReportEntry` with getter/setter, leaving existing constructors intact
- [x] 1.9 Add the six repositories under `repositories/`
- [x] 1.10 Add `specifications/RapportinoSpecification` with predicates for work, technician, status and intervention date range
- [x] 1.11 Start the app against a scratch database and verify Hibernate creates the six tables and the new nullable column without touching any existing column

## 2. Checklist template seeding

- [x] 2.1 Seed the six activity items from `prototypes/index.html:814-821` with stable codes and both locales, using the existing idempotent bootstrap-runner pattern
- [x] 2.2 Verify a second application start creates no duplicate template rows

## 3. Backend service layer

- [x] 3.1 Add `DTO/rapportini/` — create request, update request, list item response, detail response, checklist answer request/response, material request/response, signature request/response, signature-request creation request/response, public preview response, public sign request
- [x] 3.2 Implement `RapportinoNumberGenerator` producing `RFL-{year}-{sequence}` via a locked counter row or per-year Postgres sequence, never `MAX()`
- [x] 3.3 Implement `RapportinoStateMachine` allowing only DRAFT→AWAITING_SIGNATURE, DRAFT→SIGNED, AWAITING_SIGNATURE→SIGNED, AWAITING_SIGNATURE→DRAFT, SIGNED→VOID
- [x] 3.4 Implement `RapportinoService` create — resolve the work, copy the client/plant/order snapshot, assign a number, persist as DRAFT
- [x] 3.5 Implement `RapportinoService` update — replace checklist answers and materials, reject any change when status is not DRAFT, validate non-negative hours/km and positive quantities
- [x] 3.6 Implement `RapportinoService` delete — DRAFT only, cascading answers and materials
- [x] 3.7 Implement role-scoped read access: ADMIN, OWNER and ADMINISTRATION see everything; other users only their own rapportini as technician or creator — enforced in both list and single-item reads
- [x] 3.8 Implement the paginated, filtered list ordered by intervention date descending, excluding signature images from the payload
- [x] 3.9 Write service tests covering the state machine, DRAFT-only mutation, role scoping and concurrent numbering

## 4. Authenticated REST surface

- [x] 4.1 Add `RapportiniController` with POST `/rapportini`, GET `/rapportini`, GET `/rapportini/{id}`, PATCH `/rapportini/{id}`, DELETE `/rapportini/{id}`
- [x] 4.2 Add GET `/rapportini/checklist-template` returning active items in order
- [x] 4.3 Add POST `/rapportini/{id}/void` restricted to ADMIN, OWNER and ADMINISTRATION
- [x] 4.4 Add the endpoints to `AtixBackEnd/AtixBackEnd API.postman_collection.json` and exercise the full draft lifecycle manually

## 5. PDF generation and archival

- [x] 5.1 Add an HTML-to-PDF renderer to `pom.xml`, confirm it builds and renders on Spring Boot 4 / Java 21, and record the chosen library in `design.md`
- [x] 5.2 Create the rapportino document template covering every field required by the `rapportino-pdf` spec, in the rapportino's locale
- [x] 5.3 Implement `RapportinoPdfService` — render to bytes, compute a SHA-256 hash, upload through `attachmentService.uploadAndLink(file, REPORT, rapportinoId)`, store the attachment id and hash on the rapportino
- [x] 5.4 Make generation refuse to replace an existing document for an already-signed rapportino
- [x] 5.5 Add GET `/rapportini/{id}/pdf` with the same authorization as the detail endpoint, implemented per decision 0.2, and keep raw storage URLs out of every rapportino response
- [x] 5.6 Verify a rendered document against the prototype layout and confirm empty checklist and materials sections render explicitly

## 6. On-site signature and hours projection

- [x] 6.1 Implement the signature transition — validate signature image, signer name and privacy consent, persist `RapportinoSignature` with source LOCAL, set signed at and consent timestamp, move to SIGNED
- [x] 6.2 Implement hours projection inside the signature transaction — resolve or create the work's `WorkReport`, append a `WorkReportEntry` with work + travel hours, description, intervention date, technician, and the `rapportino_id` back-reference; make it idempotent on `rapportino_id`
- [x] 6.3 Chain PDF generation into the signature transition so a rendering failure never leaves a signed rapportino without a retrievable document
- [x] 6.4 Implement void — clear or zero the projected entry so it stops contributing to `WorkReport.totalHours`, record actor and timestamp, keep the document retrievable
- [x] 6.5 Reject update and delete in `WorkReportService` for entries that carry a `rapportino_id`, leaving manual entries behaving exactly as before
- [x] 6.6 Add POST `/rapportini/{id}/sign` to `RapportiniController`
- [x] 6.7 Write tests for signature validation, idempotent projection, total-hours arithmetic on sign and void, and protection of generated entries
- [x] 6.8 Confirm `WorkReport`, `WorkReportsController` and `useWorkReports.ts` remain unmodified, and that `WorkDetailPage` still renders hours correctly with a generated entry present

## 7. Remote signature — token layer

- [x] 7.1 Implement `RapportinoSignatureService` — generate a 256-bit `SecureRandom` token, persist only its SHA-256 hash with an expiry clamped to a server maximum, move the rapportino to AWAITING_SIGNATURE, return the plaintext token once
- [x] 7.2 Implement token resolution enforcing expiry, single use and revocation server-side, returning an identical result for unknown, expired, used and revoked tokens
- [x] 7.3 Implement revocation and expiry handling that returns the rapportino to DRAFT
- [x] 7.4 Reject content updates while a rapportino is AWAITING_SIGNATURE
- [x] 7.5 Add POST `/rapportini/{id}/signature-request` and POST `/rapportini/{id}/signature-request/revoke`
- [x] 7.6 Write tests for hashed storage, expiry clamping, single use, revocation and indistinguishable rejections

## 8. Remote signature — public surface

- [x] 8.1 Add `PublicSignatureController` with GET `/public/rapportini/sign/{token}` returning the minimal preview defined in the `rapportino-signature` spec
- [x] 8.2 Add POST `/public/rapportini/sign/{token}` — validate signature, signer name and consent, persist with source REMOTE plus signer IP and user agent, mark the token used, and drive the same signature transition as the on-site path
- [x] 8.3 Add exactly one `/public/**` matcher to `SecurityConfig` and confirm no other endpoint became reachable without credentials
- [x] 8.4 Add per-IP rate limiting to the public signing endpoints
- [x] 8.5 Verify the preview payload carries no internal identifiers and no data from any other rapportino or work order
- [x] 8.6 Write tests covering anonymous access to the public path, rejection of every other rapportino endpoint without credentials, single-use enforcement and consent enforcement

## 9. Frontend data layer

- [x] 9.1 Add `types/rapportino.ts` mirroring the backend DTOs
- [x] 9.2 Add `rapportiniApi` to `lib/api.ts` following the existing module pattern
- [x] 9.3 Add a separate public API client in `lib/api.ts` that does not attach the JWT, and verify no authorization header is sent on public signing calls
- [x] 9.4 Add `hooks/api/useRapportini.ts` with a query-key factory and hooks for list, detail, create, update, delete, sign, signature request, revoke and void, following the `useWorkReports.ts` and `useClients` patterns
- [x] 9.5 Invalidate the work-report query keys after signing and voiding so the work order hours refresh

## 10. Frontend signature component

- [x] 10.1 Add `components/rapportini/SignaturePad.tsx` — pointer events, DPI scaling, clear and undo, PNG export, no image emitted when nothing was drawn
- [ ] 10.2 Test it on a real tablet with finger and stylus, and on desktop with a mouse — *desktop mouse and emulated touch viewport verified headless; real tablet with finger/stylus still to do*

## 11. Frontend rapportini pages

- [x] 11.1 Add `pages/RapportiniPage.tsx` — paginated list with filters for work, technician, status and date range, plus a status badge component
- [x] 11.2 Add `pages/RapportinoDetailPage.tsx` — read-only view, document download, and the sign, signature-request, revoke, void and delete actions gated by status and role
- [x] 11.3 Add `pages/RapportinoWizardPage.tsx` with four mobile-first steps: data, activities and materials, hours and travel, signature
- [x] 11.4 Add the step components under `components/rapportini/` (checklist, materials, hours, signature)
- [x] 11.5 Make the wizard reachable only for DRAFT rapportini and render everything else read-only
- [x] 11.6 Register `/reports`, `/reports/:id` and `/reports/:id/edit` inside `ProtectedRoute` in `App.tsx`

## 12. Frontend public signing page

- [x] 12.1 Add `pages/PublicSignPage.tsx` — preview, signer name, privacy consent checkbox, `SignaturePad`, and distinct states for expired/used/invalid tokens and for success
- [x] 12.2 Register `/sign/:token` in `App.tsx` outside `ProtectedRoute`, alongside `/login`
- [x] 12.3 Verify the page renders with no session, sends no credentials, and never redirects to login

## 13. Navigation and integration

- [x] 13.1 Add the `Rapportini` entry to `mainNavItems` in `AppSidebar.tsx` after `works`, with an appropriate lucide icon and no `adminOnly` flag
- [x] 13.2 Add `menu.reports` to `locales/en/navigation.json` and `locales/it/navigation.json`
- [x] 13.3 Add `locales/{en,it}/reports.json` covering the list, detail, wizard, statuses, validation messages and the public signing page
- [x] 13.4 Add a rapportini card to `pages/WorkDetailPage.tsx` listing the work's rapportini with a "new rapportino" action that opens the wizard prefilled
- [x] 13.5 Confirm the existing hours section of `WorkDetailPage` is unchanged and still correct

## 14. Verification and rollout

- [ ] 14.1 Run `./mvnw test` and `npm run lint` clean — *`./mvnw test` 45/45 green; new frontend files lint-clean, but `npm run lint` reports 186 pre-existing errors in untouched files*
- [x] 14.2 Walk the on-site path end to end: create from a work order, fill all four steps, sign, download the document, confirm the work report total hours increased
- [x] 14.3 Walk the remote path end to end: request a link, open it on a second device with no session, sign, confirm the document and the hours projection
- [x] 14.4 Verify expiry, revocation and reuse of a signing token all fail identically and return the rapportino to DRAFT where applicable
- [x] 14.5 Verify role scoping with a technician account and an admin account against list, detail and document endpoints
- [ ] 14.6 Inspect the staging schema to confirm only additive changes were applied, then deploy
