## Why

Technicians currently record on-site interventions on paper "rapportini" (service reports) that the customer signs by hand, then re-enter the hours into AtixOps by creating `WorkReportEntry` rows. The signed paper is the billing and legal evidence of the intervention, and it lives outside the system entirely.

A standalone HTML prototype (`prototypes/index.html`) already validated the desired flow with the business (customer data → activity checklist + materials → hours/travel → customer signature on canvas → PDF). This change brings that flow into the real product so an intervention is captured once, signed digitally, archived as an immutable PDF, and its hours flow into the existing work-report ledger automatically.

## What Changes

- **New `Rapportino` domain object**: one signed service report per *intervention*, with `Work` as its mandatory parent (`1:N`). It is not an extension of `WorkReport`, which stays a `1:1` mutable hours ledger per work order.
- **Report content**: intervention type flags (maintenance / call-out / quote / warranty), description, activity checklist answers, materials used (description + quantity), ordinary and overtime hours, travel km, meal and parking flags, work progress state.
- **Immutable snapshot**: client name, client reference, plant label and order number are copied onto the rapportino so a later rename of a client or plant cannot alter an already-signed document.
- **Lifecycle with signature**: `DRAFT → AWAITING_SIGNATURE → SIGNED → VOID`. A rapportino is freely editable while `DRAFT` and frozen once `SIGNED`; corrections are made by voiding and re-issuing.
- **Two signature paths**: on-site signature on a canvas on the technician's device, and remote signature via a single-use expiring link opened by the customer on their own device.
- **New unauthenticated surface**: `/api/public/rapportini/sign/{token}` (backend) and `/sign/:token` (frontend) for the remote signature flow. This is the first non-auth surface beyond `/auth/**` and `/health`.
- **Server-side PDF generation** on signature, stored via the existing polymorphic attachment system as `AttachmentTargetType.REPORT`, and served through an authenticated endpoint rather than a raw object-storage URL.
- **Hours projection**: signing a rapportino emits a read-only `WorkReportEntry` (ordinary + overtime hours) on the work's `WorkReport`, keeping `WorkReport.totalHours` the single source of truth for work-order hours. Travel km, meal and parking stay on the rapportino only.
- **Editable checklist template**: activity items live in a seeded database table, and each answer stores a snapshot of its label so historical reports stay faithful when the template changes.
- **New frontend surfaces**: `/reports` list, `/reports/:id` detail, a 4-step mobile-first wizard, a reusable `SignaturePad` canvas component, a rapportini card inside `WorkDetailPage`, and a `Rapportini` entry in the sidebar.
- Not a breaking change: all database work is additive (new tables plus one nullable column), and no existing endpoint changes shape.

### Out of scope

- Emailing the signed PDF to the customer (`MailgunSender` currently exposes only `sendRegistrationEmail`).
- Admin CRUD UI for the checklist template (seeded rows only in this change).
- Rapportini not attached to a `Work`.
- Introducing a database migration tool (see Impact).
- A materials catalogue; materials stay free text.

## Capabilities

### New Capabilities

- `rapportini`: lifecycle of a service report attached to a work order — creation from a work, draft editing, checklist answers, materials, hours and travel data, immutable client/plant snapshot, report numbering, status transitions, role-scoped visibility, and the projection of signed hours into the existing work report.
- `rapportino-signature`: capture of the customer signature both on-site and remotely — signature storage, GDPR consent recording, single-use expiring signature-request tokens, and the unauthenticated public signing endpoints and page.
- `rapportino-pdf`: deterministic server-side rendering of a signed rapportino to PDF, its archival as a `REPORT` attachment, and authenticated retrieval of that document.

### Modified Capabilities

None. `openspec/specs/` is currently empty, so no existing spec-level behaviour changes.

## Impact

**Backend** (`AtixBackEnd`)

- New: `entities/Rapportino`, `RapportinoChecklistAnswer`, `RapportinoMaterial`, `RapportinoSignature`, `ChecklistTemplateItem`, `RapportinoSignatureRequest`; matching repositories, a `RapportinoSpecification`, `DTO/rapportini/`, `RapportinoService`, `RapportinoStateMachine`, `RapportinoNumberGenerator`, `RapportinoPdfService`, `RapportinoSignatureService`, `RapportiniController`, `PublicSignatureController`.
- Modified: `entities/WorkReportEntry` gains a nullable `rapportino_id` FK; `security/SecurityConfig` gains a `/public/**` matcher; `pom.xml` gains an HTML-to-PDF renderer.
- Untouched by design: `WorkReport`, `WorkReportService`, `WorkReportsController`.

**Frontend** (`AtixFrontEnd`)

- New: `types/rapportino.ts`, `hooks/api/useRapportini.ts`, `components/rapportini/*` (including `SignaturePad`), `pages/RapportiniPage`, `RapportinoDetailPage`, `RapportinoWizardPage`, `PublicSignPage`, `locales/{en,it}/reports.json`.
- Modified: `lib/api.ts` (adds `rapportiniApi` plus a public client that must not attach the JWT), `App.tsx` (three protected routes and one public route outside `ProtectedRoute`), `pages/WorkDetailPage.tsx`, `components/layout/AppSidebar.tsx`, `locales/{en,it}/navigation.json`.

**Database**

- The project has no Flyway or Liquibase; schema evolves through `spring.jpa.hibernate.ddl-auto = update`. This change is therefore deliberately additive-only — six new tables and one nullable column — so no destructive operation is possible. Adopting a migration tool is left to a separate change.

**Security and privacy**

- The public signing endpoints are the highest-risk area: token secrecy, server-side expiry, single use, and non-enumerable responses.
- Signed PDFs and signature images are personal data. `AttachmentService` builds direct `minio.public-url` links; whether that bucket is publicly readable is unverified and is a blocking investigation before any PDF is generated.
