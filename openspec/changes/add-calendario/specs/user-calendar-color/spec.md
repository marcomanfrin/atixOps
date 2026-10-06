## ADDED Requirements

### Requirement: Every user has a calendar colour

Every user SHALL have a calendar colour expressed as a 7-character hex string (`#RRGGBB`). User response payloads (current user, user list, user detail) and event participant payloads SHALL include it.

#### Scenario: Colour in user payloads

- **WHEN** an authenticated client requests the current user or the user list
- **THEN** each user object includes a `calendarColor` field in `#RRGGBB` form

### Requirement: Automatic colour assignment

When a user is created, and for every existing user without a colour, the system SHALL assign a colour from a fixed palette of at least 12 colours, choosing the palette colour currently used by the fewest active users (ties broken by palette order). The backfill for existing users SHALL run idempotently at application start.

#### Scenario: New user gets a colour

- **WHEN** an administrator creates a new user
- **THEN** the user is persisted with a palette colour not yet used, if one is available

#### Scenario: Backfill on start

- **WHEN** the application starts and some users have no colour
- **THEN** each of them receives a palette colour, and a second start changes nothing

#### Scenario: Palette exhausted

- **WHEN** all palette colours are already in use and a new user is created
- **THEN** the user receives the palette colour with the fewest active users

### Requirement: Self-service colour change

A user SHALL be able to change their own calendar colour. The system SHALL accept only valid `#RRGGBB` values. Colours are not required to be unique.

#### Scenario: Change own colour

- **WHEN** a user sets their colour to `#1E88E5`
- **THEN** the colour is stored and subsequent event payloads show it for that user

#### Scenario: Invalid colour rejected

- **WHEN** a user submits `blue` or `#12345` as colour
- **THEN** the system rejects the request with a validation error

### Requirement: Administrative colour change

Users with role ADMIN or OWNER SHALL be able to change the calendar colour of any user. Other users SHALL NOT be able to change someone else's colour.

#### Scenario: Admin changes a colleague's colour

- **WHEN** an ADMIN sets the colour of another user
- **THEN** the change is persisted

#### Scenario: Non-admin cannot change others

- **WHEN** a USER-role user tries to set the colour of another user
- **THEN** the system responds 403
