## ADDED Requirements

### Requirement: Rapportino belongs to a work order

A rapportino SHALL always reference exactly one existing `Work`. A `Work` SHALL be able to have many rapportini. The system SHALL reject creation of a rapportino without a valid work reference.

#### Scenario: Create from an existing work order

- **WHEN** an authenticated technician creates a rapportino for an existing work order
- **THEN** the system creates it in status `DRAFT`, links it to that work order, and returns it with a generated report number

#### Scenario: Multiple interventions on the same work order

- **WHEN** a second rapportino is created for a work order that already has a signed rapportino
- **THEN** the system creates it successfully as an independent document in status `DRAFT`

#### Scenario: Missing work order

- **WHEN** a rapportino is created with a work identifier that does not exist, or with none at all
- **THEN** the system rejects the request with a validation error and creates nothing

### Requirement: Client and plant data are snapshotted

At creation the system SHALL copy the client name, client reference, plant label and order number from the work order onto the rapportino. Rendering of a rapportino SHALL use these snapshot values rather than resolving the related entities.

#### Scenario: Prefill from the work order

- **WHEN** a rapportino is created for a work order
- **THEN** client name, client reference, plant label and order number are populated from that work order and stored on the rapportino

#### Scenario: Related entity renamed after signature

- **WHEN** the client of a work order is renamed after one of its rapportini has been signed
- **THEN** the signed rapportino still shows the client name captured at the time of signature

### Requirement: Report numbering

Every rapportino SHALL receive a unique report number of the form `RFL-{year}-{sequence}` at creation. Numbers SHALL NOT be reused, and concurrent creation SHALL NOT produce duplicates.

#### Scenario: Sequential numbering

- **WHEN** two rapportini are created in the same year
- **THEN** each receives a distinct report number sharing the same year segment

#### Scenario: Concurrent creation

- **WHEN** two technicians create a rapportino at the same moment
- **THEN** both succeed with different report numbers and no unique-constraint failure surfaces to either caller

### Requirement: Intervention content

A rapportino SHALL record intervention date, technician, intervention type flags (maintenance, call-out, quote/order, warranty), a free-text description, ordinary hours, overtime hours, travel kilometres, meal and parking flags, and a work progress state of `IN_PROGRESS` or `COMPLETED`. Hours and kilometres SHALL NOT be negative.

#### Scenario: Save intervention data

- **WHEN** a technician saves a draft rapportino with intervention date, description, hours and travel data
- **THEN** the system persists all provided values and returns the updated rapportino

#### Scenario: Negative hours rejected

- **WHEN** a draft rapportino is saved with negative ordinary hours
- **THEN** the system rejects the request with a validation error and persists nothing

### Requirement: Activity checklist

The system SHALL provide a checklist template of activity items, seeded on first start and readable by authenticated users. A rapportino SHALL store one answer row per selected template item, each carrying a checked flag, an optional note, and a snapshot of the item label at the time of answering.

#### Scenario: Read the template

- **WHEN** an authenticated user requests the checklist template
- **THEN** the system returns the active items in their configured order

#### Scenario: Answer stores a label snapshot

- **WHEN** a technician checks an activity item on a draft rapportino
- **THEN** the stored answer carries the current label text of that item

#### Scenario: Template item edited later

- **WHEN** a template item label is changed after a rapportino answered it
- **THEN** the existing rapportino still displays the label captured when it was answered

### Requirement: Materials used

A rapportino SHALL record any number of materials, each with a free-text description and a quantity, kept in a stable display order. Quantity SHALL be greater than zero.

#### Scenario: Add materials

- **WHEN** a technician adds two materials to a draft rapportino
- **THEN** both are persisted and returned in the order they were entered

#### Scenario: Remove a material

- **WHEN** a technician removes a material from a draft rapportino
- **THEN** it is deleted from the rapportino and the remaining materials keep their relative order

### Requirement: Status lifecycle

A rapportino SHALL have exactly one status among `DRAFT`, `AWAITING_SIGNATURE`, `SIGNED` and `VOID`. Permitted transitions are `DRAFT → AWAITING_SIGNATURE`, `DRAFT → SIGNED`, `AWAITING_SIGNATURE → SIGNED`, `AWAITING_SIGNATURE → DRAFT`, and `SIGNED → VOID`. Any other transition SHALL be rejected.

#### Scenario: Invalid transition rejected

- **WHEN** a request attempts to move a `VOID` rapportino back to `DRAFT`
- **THEN** the system rejects it with a conflict error and the status is unchanged

#### Scenario: Return to draft on expiry

- **WHEN** the signature request of an `AWAITING_SIGNATURE` rapportino expires or is revoked
- **THEN** the rapportino returns to `DRAFT` and becomes editable again

### Requirement: Signed rapportini are immutable

A rapportino in status `SIGNED` or `VOID` SHALL reject every content modification and SHALL NOT be deleted. Deletion SHALL be permitted only in status `DRAFT`.

#### Scenario: Edit after signature

- **WHEN** any update is submitted for a `SIGNED` rapportino
- **THEN** the system rejects it with a conflict error and no field changes

#### Scenario: Delete a signed rapportino

- **WHEN** a delete is requested for a `SIGNED` rapportino
- **THEN** the system rejects it with a conflict error

#### Scenario: Delete a draft

- **WHEN** a delete is requested for a `DRAFT` rapportino by a user allowed to see it
- **THEN** the rapportino and its checklist answers and materials are removed

### Requirement: Void and reissue

An administrator SHALL be able to void a signed rapportino, recording who voided it and when. Correcting a signed rapportino SHALL be done by voiding it and creating a new one that references the voided document.

#### Scenario: Void a signed rapportino

- **WHEN** an administrator voids a `SIGNED` rapportino
- **THEN** its status becomes `VOID`, the actor and timestamp are recorded, and its document remains retrievable

#### Scenario: Technician cannot void

- **WHEN** a technician without administrative rights attempts to void a signed rapportino
- **THEN** the system rejects the request with an authorization error

### Requirement: Signed hours flow into the work report

On transition to `SIGNED`, the system SHALL append one entry to the work order's `WorkReport`, creating that report if absent, with hours equal to ordinary plus overtime hours, the intervention description, the intervention date and the technician as author. The entry SHALL reference its originating rapportino. Travel kilometres, meal and parking SHALL NOT be projected.

#### Scenario: Entry created on signature

- **WHEN** a rapportino with 4 ordinary and 2 overtime hours is signed
- **THEN** a work report entry of 6 hours referencing that rapportino exists on the work order and the report total hours increase by 6

#### Scenario: Work report absent

- **WHEN** the first rapportino of a work order with no existing work report is signed
- **THEN** the system creates the work report and adds the entry to it

#### Scenario: Projection is idempotent

- **WHEN** the signature transition is retried for a rapportino that already produced an entry
- **THEN** no second entry is created and the report total hours are unchanged

#### Scenario: Void removes the projected hours

- **WHEN** a signed rapportino is voided
- **THEN** its generated work report entry no longer contributes to the work report total hours

### Requirement: Generated work report entries are protected

A `WorkReportEntry` that originates from a rapportino SHALL NOT be updated or deleted through the work-report endpoints.

#### Scenario: Update a generated entry

- **WHEN** an update is submitted for a work report entry that references a rapportino
- **THEN** the system rejects it with a conflict error

#### Scenario: Manual entries unaffected

- **WHEN** an update is submitted for a work report entry created manually
- **THEN** it succeeds exactly as before this change

### Requirement: Role-scoped visibility

The system SHALL restrict rapportino visibility by role. Users with role `ADMIN` or `OWNER`, and users of type `ADMINISTRATION`, SHALL see all rapportini. Other users SHALL see only rapportini where they are the assigned technician or the creator. Filtering SHALL be enforced server-side.

#### Scenario: Technician lists rapportini

- **WHEN** a technician requests the rapportino list
- **THEN** the response contains only rapportini where that user is the technician or the creator

#### Scenario: Technician requests another user's rapportino

- **WHEN** a technician requests a rapportino belonging to a different technician by its identifier
- **THEN** the system denies access

#### Scenario: Administrator lists rapportini

- **WHEN** an administrator requests the rapportino list
- **THEN** the response contains rapportini from all technicians

### Requirement: Filterable list

The system SHALL expose a paginated rapportino list filterable by work order, technician, status and intervention date range, ordered by intervention date descending by default. List responses SHALL NOT include signature images.

#### Scenario: Filter by status and date range

- **WHEN** a user requests rapportini with status `SIGNED` within a date range
- **THEN** the response contains only signed rapportini whose intervention date falls inside that range

#### Scenario: List excludes signature data

- **WHEN** any rapportino list is requested
- **THEN** no signature image is present in the response payload

### Requirement: Rapportini are reachable from the work order and from a dedicated page

The application SHALL provide a dedicated rapportini list page reachable from the main sidebar navigation, a detail page per rapportino, and a rapportini section on the work order detail page that can start a new rapportino prefilled with that work order.

#### Scenario: Navigate from the sidebar

- **WHEN** an authenticated user selects the rapportini entry in the sidebar
- **THEN** the rapportini list page opens showing the rapportini visible to that user

#### Scenario: Start from a work order

- **WHEN** a technician starts a new rapportino from a work order detail page
- **THEN** the wizard opens with that work order and its snapshot data prefilled

#### Scenario: Edit restricted to drafts

- **WHEN** a user opens a rapportino that is not in status `DRAFT`
- **THEN** the detail page is read-only and offers no editing action
