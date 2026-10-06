## ADDED Requirements

### Requirement: On-site signature capture

An authenticated technician SHALL be able to sign a `DRAFT` rapportino on their own device by submitting a signature image, the signer's name and an explicit privacy consent. The system SHALL store the signature, the signer name, the signature timestamp, the consent timestamp and a signature source of `LOCAL`, and SHALL move the rapportino to `SIGNED`.

#### Scenario: Successful on-site signature

- **WHEN** a technician submits a signature image, signer name and privacy consent for a `DRAFT` rapportino
- **THEN** the rapportino becomes `SIGNED`, the signature and signer name are stored with source `LOCAL`, and the signature timestamp is recorded

#### Scenario: Missing privacy consent

- **WHEN** a signature is submitted without privacy consent
- **THEN** the system rejects the request with a validation error and the rapportino stays `DRAFT`

#### Scenario: Missing signature image

- **WHEN** a signature is submitted with an empty or malformed signature image
- **THEN** the system rejects the request with a validation error and the rapportino stays `DRAFT`

#### Scenario: Signing an already signed rapportino

- **WHEN** a signature is submitted for a rapportino already in status `SIGNED`
- **THEN** the system rejects the request with a conflict error and the existing signature is preserved

### Requirement: Signature images are never exposed in bulk

The signature image SHALL be stored separately from the rapportino record and SHALL be returned only in the single-rapportino detail response and in the generated document.

#### Scenario: Detail response

- **WHEN** an authorized user requests a signed rapportino by its identifier
- **THEN** the response includes the signature image

#### Scenario: List response

- **WHEN** any rapportino list or search result is returned
- **THEN** no signature image is included

### Requirement: Remote signature request

An authenticated technician SHALL be able to request a remote signature for a `DRAFT` rapportino, choosing an expiry within a server-enforced maximum. The system SHALL generate a cryptographically random single-use token, store only its hash together with the expiry, move the rapportino to `AWAITING_SIGNATURE`, and return a signing URL containing the plaintext token.

#### Scenario: Create a signature request

- **WHEN** a technician requests a remote signature with a 60-minute expiry
- **THEN** the system returns a signing URL and expiry time, and the rapportino becomes `AWAITING_SIGNATURE`

#### Scenario: Token stored hashed

- **WHEN** a signature request is created
- **THEN** the stored record contains only a hash of the token and the plaintext token appears nowhere in persistent storage

#### Scenario: Expiry beyond the allowed maximum

- **WHEN** a signature request is created with an expiry longer than the server maximum
- **THEN** the system rejects the request or clamps it to the maximum, and never issues a token exceeding it

#### Scenario: Content frozen while awaiting signature

- **WHEN** a content update is submitted for a rapportino in status `AWAITING_SIGNATURE`
- **THEN** the system rejects it with a conflict error

### Requirement: Signature request revocation and expiry

A technician SHALL be able to revoke an outstanding signature request. A revoked or expired request SHALL no longer be usable, and its rapportino SHALL return to `DRAFT`.

#### Scenario: Revoke an outstanding request

- **WHEN** a technician revokes the signature request of an `AWAITING_SIGNATURE` rapportino
- **THEN** the token stops working and the rapportino returns to `DRAFT`

#### Scenario: Use an expired token

- **WHEN** the public signing page is opened with a token whose expiry has passed
- **THEN** the system refuses the request and no rapportino data is returned

### Requirement: Public signing preview

The system SHALL expose an unauthenticated endpoint that, given a valid token, returns a read-only preview of the rapportino limited to report number, intervention date, client name, plant label, description, checklist answers, materials and hour totals. The preview SHALL NOT include internal identifiers, technician contact data, other rapportini, or any other work order.

#### Scenario: Valid token preview

- **WHEN** the customer opens the signing link with a valid, unused, unexpired token
- **THEN** the system returns the intervention summary needed to review and sign

#### Scenario: Preview payload is minimal

- **WHEN** the preview is returned
- **THEN** it contains no internal identifiers and no data belonging to any other rapportino or work order

#### Scenario: No authentication required

- **WHEN** the signing link is opened with no session and no authorization header
- **THEN** the request succeeds and no authentication challenge is issued

### Requirement: Public signature submission

The system SHALL expose an unauthenticated endpoint that accepts a signature image, signer name and privacy consent for a valid token. On success it SHALL store the signature with source `REMOTE`, record the signer's IP address and user agent, mark the token used, and move the rapportino to `SIGNED`.

#### Scenario: Customer signs remotely

- **WHEN** the customer submits a signature, name and consent through a valid token
- **THEN** the rapportino becomes `SIGNED` with signature source `REMOTE`, and the signing IP and user agent are recorded

#### Scenario: Token is single use

- **WHEN** a signature submission is attempted with a token that was already used
- **THEN** the system refuses it and the original signature is unchanged

#### Scenario: Consent required remotely

- **WHEN** a remote signature is submitted without privacy consent
- **THEN** the system rejects it and the rapportino stays `AWAITING_SIGNATURE`

### Requirement: Signing tokens are not probeable

Requests carrying an unknown, expired, already used or revoked token SHALL produce an indistinguishable response. The public signing endpoints SHALL be rate-limited per client address.

#### Scenario: Indistinguishable rejections

- **WHEN** the signing endpoint is called with an unknown token and then with an expired token
- **THEN** both calls return the same status and the same body, revealing nothing about which condition applied

#### Scenario: Rate limiting

- **WHEN** a single client address exceeds the configured request rate against the public signing endpoints
- **THEN** further requests are refused until the limit window elapses

### Requirement: Public surface is narrowly scoped

Only the public signing endpoints SHALL be reachable without authentication, in addition to the already-public authentication and health endpoints. Every other rapportino endpoint SHALL require authentication.

#### Scenario: Authenticated endpoints stay protected

- **WHEN** any rapportino endpoint outside the public signing path is called without credentials
- **THEN** the request is rejected as unauthorized

#### Scenario: Public page sends no credentials

- **WHEN** the public signing page issues its requests
- **THEN** no authentication token is attached to them

### Requirement: Reusable signature capture component

The application SHALL provide a single signature capture component used by both the technician wizard and the public signing page, supporting touch, stylus and mouse input on high-density displays, with clear and undo actions, and producing an image only when a signature has actually been drawn.

#### Scenario: Draw and submit

- **WHEN** a signer draws on the signature area and confirms
- **THEN** the drawn signature is captured as an image and submitted

#### Scenario: Clear the signature

- **WHEN** a signer clears the signature area
- **THEN** the area is empty and submission is not allowed until a new signature is drawn

#### Scenario: Empty signature blocked

- **WHEN** a signer confirms without drawing anything
- **THEN** the interface blocks submission and explains that a signature is required
