## ADDED Requirements

### Requirement: PDF generated on signature

The system SHALL render a PDF of the rapportino on the server as part of the signature transition, for both on-site and remote signatures. The signature transition SHALL be atomic with respect to the rapportino status: if rendering or archiving fails, the rapportino SHALL NOT be left in an inconsistent state.

#### Scenario: Document produced on on-site signature

- **WHEN** a rapportino is signed on the technician's device
- **THEN** a PDF of that rapportino is generated server-side and linked to it

#### Scenario: Document produced on remote signature

- **WHEN** a rapportino is signed by the customer through a signing link
- **THEN** a PDF of that rapportino is generated server-side and linked to it, without any browser involvement in producing the document

#### Scenario: Rendering failure

- **WHEN** PDF rendering fails during the signature transition
- **THEN** the operation reports an error and the rapportino is not left marked as signed without a retrievable document

### Requirement: Document content

The generated PDF SHALL contain the report number, intervention date, snapshotted client name, client reference, plant label and order number, intervention type flags, the description, all checklist answers with their snapshotted labels, all materials with quantities, ordinary hours, overtime hours, travel kilometres, meal and parking flags, work progress state, technician name, signer name, the signature image and the signature timestamp.

#### Scenario: Complete rapportino rendered

- **WHEN** a rapportino with checklist answers, materials and a signature is rendered
- **THEN** every recorded field listed above appears in the resulting document

#### Scenario: Empty sections

- **WHEN** a rapportino with no materials and no checked activities is rendered
- **THEN** the document renders successfully and marks those sections as empty rather than omitting them silently

### Requirement: Documents are archived as report attachments

The generated PDF SHALL be stored through the existing attachment system, linked with target type `REPORT` to the rapportino and typed as a PDF attachment. The rapportino SHALL retain a reference to that attachment.

#### Scenario: Attachment created and linked

- **WHEN** a rapportino is signed
- **THEN** a PDF attachment linked to that rapportino with target type `REPORT` exists and the rapportino references it

#### Scenario: Voided rapportino keeps its document

- **WHEN** a signed rapportino is voided
- **THEN** its archived document remains retrievable

### Requirement: Documents are served only through an authenticated endpoint

The system SHALL expose an authenticated endpoint to retrieve a rapportino's document, applying the same visibility rules as the rapportino detail. Rapportino responses SHALL NOT expose a raw object-storage URL for the document.

#### Scenario: Authorized download

- **WHEN** a user allowed to see a signed rapportino requests its document
- **THEN** the system delivers the PDF

#### Scenario: Unauthorized download

- **WHEN** a technician requests the document of a rapportino belonging to another technician
- **THEN** the system denies access

#### Scenario: Anonymous download

- **WHEN** the document endpoint is called without credentials
- **THEN** the request is rejected as unauthorized

#### Scenario: No raw storage URL in responses

- **WHEN** a rapportino detail or list response is returned
- **THEN** it contains no directly usable object-storage URL for the document

### Requirement: Document integrity

The system SHALL record a content hash of each generated document, and SHALL NOT regenerate or replace the document of a rapportino that is already signed.

#### Scenario: Hash recorded

- **WHEN** a document is generated
- **THEN** a hash of its bytes is stored alongside the rapportino

#### Scenario: Regeneration refused

- **WHEN** document generation is requested again for an already-signed rapportino
- **THEN** the system returns the existing document and does not produce a new one

### Requirement: Draft rapportini have no document

A rapportino SHALL NOT have an archived document while in status `DRAFT` or `AWAITING_SIGNATURE`.

#### Scenario: Document requested for a draft

- **WHEN** the document of a `DRAFT` rapportino is requested
- **THEN** the system reports that no document exists yet
