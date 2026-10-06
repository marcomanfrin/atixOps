## ADDED Requirements

### Requirement: Calendar page and navigation entry

The frontend SHALL provide a protected `/calendar` page reachable from a `Calendario` / `Calendar` entry in the sidebar. The page SHALL offer two views — Month and Gantt — switchable by a toggle, and SHALL remember the last chosen view and the "only mine" filter per browser.

#### Scenario: Open the calendar

- **WHEN** an authenticated user clicks the sidebar entry
- **THEN** the `/calendar` page opens in the last used view, defaulting to Month

#### Scenario: Switch view

- **WHEN** the user switches from Month to Gantt
- **THEN** the Gantt view shows the same date range anchor and the same filters

### Requirement: Month view

The Month view SHALL render a month grid of weeks starting on Monday, including leading and trailing days of adjacent months. Each day cell SHALL list the events overlapping that day, ordered by start time, showing start time (unless all-day) and title. Multi-day events SHALL appear on every day they cover. Each event SHALL be drawn with its participants' colours: a single participant fills the chip with that colour; multiple participants show one colour segment per participant. When a cell has more events than fit, it SHALL show a "+N" indicator that reveals the full list for that day.

#### Scenario: Single-participant event colour

- **WHEN** an event has one participant whose colour is `#E53935`
- **THEN** its chip in the month grid uses `#E53935`

#### Scenario: Group event colours

- **WHEN** an event has three participants
- **THEN** its chip shows three colour segments, one per participant, in participant name order

#### Scenario: Multi-day event

- **WHEN** an event runs from Monday to Wednesday
- **THEN** it appears in the Monday, Tuesday and Wednesday cells

#### Scenario: Overflowing day

- **WHEN** a day has more events than the cell can display
- **THEN** the cell shows the first events and a "+N" control that opens the complete list of that day

### Requirement: Gantt view

The Gantt view SHALL render one row per user and a horizontal time axis with one column per day, for a selectable span of one week, two weeks or one month. Each event SHALL be drawn as a horizontal bar on the row of every participant, positioned and sized according to its start and end, in that participant's colour. Overlapping events on the same row SHALL be stacked so that none is hidden. Today SHALL be highlighted, and weekends SHALL be visually distinguished. Rows SHALL show the user's name and a colour swatch.

#### Scenario: Group event in Gantt

- **WHEN** an event has participants Anna and Luca
- **THEN** a bar appears on Anna's row in Anna's colour and on Luca's row in Luca's colour, spanning the same interval

#### Scenario: Overlapping events

- **WHEN** a user has two events overlapping on the same day
- **THEN** both bars are visible, stacked in separate lanes of that user's row

#### Scenario: Change span

- **WHEN** the user switches the Gantt span from week to month
- **THEN** the axis shows every day of the anchor month and bars are recomputed

#### Scenario: Users without events

- **WHEN** the "only mine" filter is off and no participant filter is set
- **THEN** every active user has a row, even if empty, so free availability is visible

### Requirement: "Only my commitments" filter

Both views SHALL offer an "only my commitments" toggle. When on, only events where the current user is a participant SHALL be shown, and the Gantt view SHALL show only the current user's row.

#### Scenario: Toggle on in Month view

- **WHEN** the user enables "only mine"
- **THEN** the month grid shows only events in which they are a participant

#### Scenario: Toggle on in Gantt view

- **WHEN** the user enables "only mine" in the Gantt view
- **THEN** only their own row is shown with their events

### Requirement: Participant filter and legend

Both views SHALL offer a multi-select participant filter and a legend listing users with their colour. Selecting participants SHALL restrict the displayed events (and Gantt rows) to those users.

#### Scenario: Filter two colleagues

- **WHEN** the user selects two colleagues in the participant filter
- **THEN** only events involving at least one of them are shown, and the Gantt view shows only their rows

### Requirement: Date navigation

Both views SHALL provide previous, next and today controls and display the current period label in the active locale. The data request SHALL cover exactly the visible range.

#### Scenario: Navigate months

- **WHEN** the user clicks "next" in Month view on October 2026
- **THEN** November 2026 is displayed and events for its visible grid range are fetched

### Requirement: Create and edit dialog

The page SHALL provide a dialog to create and edit events with title, description, location, all-day toggle, start and end date/time, participants multi-select (defaulting to the current user on creation), and optional work-order link. The dialog SHALL open empty from a "New commitment" button, prefilled with a date when clicking an empty day cell or Gantt cell (prefilling the row's user as participant in Gantt), and prefilled with the event when clicking an existing event. Events the caller cannot edit SHALL open read-only. A delete action with confirmation SHALL be available on editable events. After save or delete the views SHALL refresh.

#### Scenario: Quick create from a day

- **WHEN** the user clicks an empty area of 2026-10-20 in Month view
- **THEN** the dialog opens with start and end on 2026-10-20 and the current user as participant

#### Scenario: Create from a Gantt row

- **WHEN** the user clicks on Luca's row at 2026-10-21 in Gantt view
- **THEN** the dialog opens with date 2026-10-21 and Luca as participant

#### Scenario: Read-only event

- **WHEN** a user opens an event they neither created nor can administer
- **THEN** the dialog shows the details without editable fields or delete action

#### Scenario: Validation in the dialog

- **WHEN** the user tries to save with no participants or an end before the start
- **THEN** the dialog shows a localised validation error and does not submit

### Requirement: Internationalisation

All calendar labels, weekday and month names, and validation messages SHALL be available in Italian and English, following the active application language.

#### Scenario: Italian locale

- **WHEN** the application language is Italian
- **THEN** weekdays, month names and labels are shown in Italian and weeks start on Monday
