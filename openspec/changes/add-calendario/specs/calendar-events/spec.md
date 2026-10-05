## ADDED Requirements

### Requirement: Calendar event content

A calendar event SHALL record a title (required, max 200 characters), an optional description, an optional location, a start date-time, an end date-time, an all-day flag, the creating user, creation and update timestamps, and an optional reference to an existing `Work`. The end SHALL NOT be before the start. For all-day events the system SHALL store the start at 00:00 of the first day and the end at 00:00 of the day after the last day.

#### Scenario: Create a timed event

- **WHEN** an authenticated user creates an event with title, start 2026-10-12 09:00 and end 2026-10-12 11:30
- **THEN** the system persists the event, records the caller as creator, and returns it with its identifier

#### Scenario: Create an all-day multi-day event

- **WHEN** a user creates an all-day event from 2026-10-12 to 2026-10-14 inclusive
- **THEN** the system stores start 2026-10-12 00:00 and end 2026-10-15 00:00 with the all-day flag set

#### Scenario: End before start rejected

- **WHEN** a user submits an event whose end precedes its start
- **THEN** the system rejects the request with a validation error and persists nothing

#### Scenario: Missing title rejected

- **WHEN** a user submits an event with an empty title
- **THEN** the system rejects the request with a validation error

#### Scenario: Link to a work order

- **WHEN** a user creates an event referencing an existing work order
- **THEN** the event is stored with that work reference and the response includes the work identifier and its label

#### Scenario: Link to a non-existent work order

- **WHEN** a user creates an event referencing a work identifier that does not exist
- **THEN** the system rejects the request with a not-found error

### Requirement: Participants

An event SHALL have one or more participants chosen among active (not soft-deleted) users. The creator SHALL be able to add themselves, other users, or both. The creator SHALL NOT be implicitly added as a participant. Duplicate participants SHALL be collapsed.

#### Scenario: Event for myself

- **WHEN** a user creates an event with only themselves as participant
- **THEN** the event has exactly one participant, the caller

#### Scenario: Event for a colleague

- **WHEN** a user creates an event with only a colleague as participant
- **THEN** the event has that colleague as sole participant and the caller as creator

#### Scenario: Event for several people

- **WHEN** a user creates an event with three participants including themselves
- **THEN** the event is stored once and linked to all three participants

#### Scenario: No participants rejected

- **WHEN** a user submits an event with an empty participant list
- **THEN** the system rejects the request with a validation error

#### Scenario: Deleted user as participant rejected

- **WHEN** a user submits an event whose participants include a soft-deleted or unknown user
- **THEN** the system rejects the request and persists nothing

### Requirement: Shared visibility

Every authenticated user SHALL be able to read every calendar event, regardless of creator and participants. Unauthenticated requests SHALL be rejected.

#### Scenario: See a colleague's event

- **WHEN** a user lists events in a window containing an event where they are neither creator nor participant
- **THEN** that event is included in the response

#### Scenario: Unauthenticated access

- **WHEN** a request without a valid JWT calls any calendar endpoint
- **THEN** the system responds 401

### Requirement: Edit and delete permissions

The creator of an event and users with role ADMIN or OWNER SHALL be able to update or delete it. Other users, including participants who are not the creator, SHALL NOT be able to update or delete it. Updates SHALL replace the participant set with the one provided.

#### Scenario: Creator edits

- **WHEN** the creator changes the time and participants of their event
- **THEN** the system persists the new values and the new participant set

#### Scenario: Admin edits another user's event

- **WHEN** an ADMIN updates an event created by someone else
- **THEN** the update succeeds

#### Scenario: Participant cannot edit

- **WHEN** a participant who is not the creator and not ADMIN/OWNER tries to update or delete the event
- **THEN** the system responds 403 and nothing changes

#### Scenario: Delete

- **WHEN** the creator deletes an event
- **THEN** the event and its participant links are removed and it no longer appears in any list

### Requirement: Range query

The system SHALL expose a list endpoint that returns all events overlapping a requested time window `[from, to)`, i.e. events with `start < to` and `end > from`. Both bounds SHALL be required and the window SHALL NOT exceed 100 days. Results SHALL be ordered by start ascending and SHALL include, for each event, its participants with id, full name and calendar colour, the creator id and name, the optional work reference, and a flag telling whether the caller can edit it.

#### Scenario: Event spanning the window boundary

- **WHEN** a user requests October 2026 and an event runs from 2026-09-29 to 2026-10-02
- **THEN** the event is included

#### Scenario: Event outside the window

- **WHEN** a user requests October 2026 and an event ends exactly at 2026-10-01 00:00
- **THEN** the event is not included

#### Scenario: Window too large

- **WHEN** a user requests a window longer than 100 days, or omits `from` or `to`
- **THEN** the system rejects the request with a validation error

#### Scenario: Editable flag

- **WHEN** a non-admin user lists events
- **THEN** events they created are flagged editable and all others are flagged not editable

### Requirement: Participant and "mine" filters

The list endpoint SHALL accept an optional `mine` flag and an optional list of participant identifiers. When `mine` is true the system SHALL return only events where the caller is a participant. When participant identifiers are given the system SHALL return only events having at least one of those participants. When both are given, both conditions SHALL apply.

#### Scenario: Only my commitments

- **WHEN** a user lists with `mine=true`
- **THEN** only events in which the caller is a participant are returned, including those created by others

#### Scenario: Events I created for others are excluded by mine

- **WHEN** a user lists with `mine=true` and has created an event only for a colleague
- **THEN** that event is not returned

#### Scenario: Filter by participants

- **WHEN** a user lists with participant identifiers of two colleagues
- **THEN** only events involving at least one of those two colleagues are returned
