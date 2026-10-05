## Why

Today AtixOps has no shared view of who is doing what and when. Work orders carry an `expectedStartDate`, but appointments, site visits, meetings, holidays and other commitments of technicians, administration and sellers live in personal agendas, so it is hard to plan an intervention or to know whether a colleague is available.

A shared team calendar inside the product lets every user record commitments for themselves or for colleagues, and lets the whole team see the workload at a glance, both as a month calendar and as a per-person Gantt timeline.

## What Changes

- **New `CalendarEvent` domain object** ("impegno"): title, optional description, optional location, start and end date-time, all-day flag, creator, and one or more participants. An event can optionally be linked to an existing `Work`.
- **Events for self, for others, or for groups**: any authenticated user can create an event and choose its participants among active users — only themselves, one or more colleagues, or both. At least one participant is required.
- **Per-user colour**: every user gets a calendar colour. It is assigned automatically from a fixed palette when missing, each user can change their own from the profile page, and ADMIN/OWNER can change anyone's from the users page.
- **Shared visibility**: every authenticated user can see every event in the team calendar. Edit and delete are allowed to the creator and to ADMIN/OWNER.
- **Range-based REST API**: `/calendar-events` with CRUD plus a list endpoint filtered by time window (`from`, `to`), participants, and a `mine` flag.
- **New frontend page `/calendar`** with two views on the same data:
  - **Month view**: a classic month grid; each event is drawn in its participants' colours.
  - **Gantt view**: one row per user, horizontal time axis (week / two weeks / month), each event drawn as a bar in that user's colour on every participant's row.
- **"Only my commitments" filter** shared by both views, plus a participant filter, a colour legend, and navigation (previous / today / next).
- **Create / edit dialog** opened from a button, a day cell, or an existing event.
- Sidebar entry `Calendario` and new `calendar` i18n namespace (it/en).
- Not a breaking change: database work is additive (two new tables and one nullable column on `users`).

### Out of scope

- Recurring events.
- Email or push notifications and invitations with accept/decline.
- Sync with external calendars (Google, Outlook, iCal export/import).
- Private events hidden from other users.
- Conflict detection or blocking of overlapping commitments (overlaps are allowed and simply shown).
- Automatic creation of events from work orders.

## Capabilities

### New Capabilities

- `calendar-events`: lifecycle of a calendar commitment — creation for self, others or groups, participants, time window and all-day events, optional work-order link, edit/delete permissions, shared visibility, and the range/participant/"mine" query API.
- `user-calendar-color`: the colour associated to each user — automatic assignment from a palette, validation, self-service change and administrative change, exposure in user payloads.
- `calendar-views`: the frontend `/calendar` page — month view, Gantt view, "only mine" and participant filters, legend, navigation and the create/edit dialog.

### Modified Capabilities

None. `openspec/specs/` is currently empty.

## Impact

**Backend** (`AtixBackEnd`)

- New: `entities/CalendarEvent`, `repositories/CalendarEventRepository`, `specifications/CalendarEventSpecification`, `DTO/calendar/`, `services/CalendarEventService`, `services/UserColorService` (palette assignment), `controllers/CalendarEventsController`.
- Modified: `entities/users/User` gains a nullable `calendarColor` column; user response DTOs expose it; `UsersController` gains endpoints to change the colour (self and admin).

**Frontend** (`AtixFrontEnd`)

- New: `types/calendar.ts`, `hooks/api/useCalendarEvents.ts`, `components/calendar/*` (`MonthView`, `GanttView`, `EventDialog`, `CalendarToolbar`, `UserColorLegend`, `ParticipantPicker`), `pages/CalendarPage.tsx`, `locales/{en,it}/calendar.json`.
- Modified: `lib/api.ts`, `App.tsx` (route `/calendar`), `components/layout/AppSidebar.tsx`, `locales/{en,it}/navigation.json`, `pages/ProfilePage.tsx` (colour picker), `pages/UsersPage.tsx` (colour column / picker), `types` for users.
- No new npm dependency: both views are built on `date-fns` (already present) and Tailwind.

**Database**

- Schema evolves via `ddl-auto = update`; this change is additive only: `calendar_events`, `calendar_event_participants`, and nullable `users.calendar_color`.
