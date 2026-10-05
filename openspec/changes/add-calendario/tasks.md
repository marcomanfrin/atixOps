## 1. Backend domain model

- [ ] 1.1 Add nullable `calendarColor` (`calendar_color`, length 7) to `entities/users/User` with getter/setter
- [ ] 1.2 Add `entities/CalendarEvent` — UUID id, title (not null, 200), description (text), location, startAt, endAt, allDay, work (nullable `@ManyToOne`), createdBy (not null), createdAt/updatedAt via `@PrePersist`/`@PreUpdate`, `@ManyToMany Set<User> participants` on join table `calendar_event_participants`
- [ ] 1.3 Add index on `(start_at, end_at)` via `@Table(indexes = …)`
- [ ] 1.4 Add `repositories/CalendarEventRepository` extending `JpaSpecificationExecutor`, with an entity graph loading participants, creator and work
- [ ] 1.5 Add `specifications/CalendarEventSpecification` — overlap(from, to), participantIn(ids), hasParticipant(userId), with `distinct`
- [ ] 1.6 Start the app against a scratch database and verify Hibernate creates the two tables and the nullable column without altering existing columns

## 2. User colour

- [ ] 2.1 Implement `services/UserColorService` with the fixed palette and `pickColor()` (least-used among active users, ties by palette order)
- [ ] 2.2 Assign a colour in the existing user-creation path(s)
- [ ] 2.3 Add an idempotent `ApplicationRunner` that backfills users with null colour
- [ ] 2.4 Expose `calendarColor` in all user response DTOs and in the current-user endpoint
- [ ] 2.5 Add `PATCH /users/me/calendar-color` and `PATCH /users/{id}/calendar-color` (ADMIN/OWNER) with `#RRGGBB` validation
- [ ] 2.6 Tests: palette selection, backfill idempotency, validation, 403 for non-admin on others

## 3. Calendar events service and API

- [ ] 3.1 Add `DTO/calendar/` — `CalendarEventRequest` (title, description, location, startAt, endAt, allDay, participantIds, workId) with Bean Validation, `CalendarEventResponse` (… participants [id, fullName, calendarColor], createdBy [id, fullName], work [id, label], canEdit), `CalendarParticipantResponse`
- [ ] 3.2 Implement `CalendarEventService.create` — validate end ≥ start, normalise all-day to midnight boundaries, resolve and validate participants (non-empty, active, deduplicated), resolve optional work, set creator
- [ ] 3.3 Implement `update` and `delete` with creator-or-ADMIN/OWNER check (403 otherwise), replacing the participant set on update
- [ ] 3.4 Implement `list(from, to, mine, participantIds)` — require both bounds, reject windows > 100 days, order by start, compute `canEdit` per caller
- [ ] 3.5 Implement `get(id)`
- [ ] 3.6 Add `controllers/CalendarEventsController`: `GET /calendar-events`, `GET /calendar-events/{id}`, `POST`, `PUT /calendar-events/{id}`, `DELETE /calendar-events/{id}`
- [ ] 3.7 Ensure events referencing a work order survive if the work is removed (null the reference)
- [ ] 3.8 Tests: overlap boundaries (touching end excluded), all-day normalisation, participants validation, `mine` semantics (created-for-others excluded), permissions, no N+1 on list
- [ ] 3.9 Add the endpoints to `API_DOCUMENTATION.md` and the Postman collection

## 4. Frontend data layer

- [ ] 4.1 Add `types/calendar.ts` (`CalendarEvent`, `CalendarEventInput`, `CalendarParticipant`) and `calendarColor` on the user type
- [ ] 4.2 Add `calendarApi` and user colour calls to `lib/api.ts`
- [ ] 4.3 Add `hooks/api/useCalendarEvents.ts` — `useCalendarEvents({from, to, mine, participantIds})`, `useCreate/Update/DeleteCalendarEvent` invalidating the calendar query key; `useUpdateCalendarColor`
- [ ] 4.4 Add a colour utility returning readable text colour (black/white) from a hex background

## 5. Frontend calendar page

- [ ] 5.1 Add `pages/CalendarPage.tsx` with state (view, anchorDate, ganttSpan, onlyMine, participantIds), derived visible range, and `localStorage` persistence for view and onlyMine (wrapped in try/catch)
- [ ] 5.2 Add `components/calendar/CalendarToolbar` — prev/today/next, period label, Month/Gantt toggle, Gantt span selector, "only mine" switch, participant multi-select, "New commitment" button
- [ ] 5.3 Add `components/calendar/UserColorLegend`
- [ ] 5.4 Add `components/calendar/MonthView` — Monday-first grid, per-day bucketing of multi-day events, single/multi-participant chip colouring, "+N" popover, click empty cell → create, click event → open
- [ ] 5.5 Add `components/calendar/GanttView` — sticky user column with swatch, day columns, weekend and today highlight, bars per participant row in that user's colour, greedy lane packing, horizontal scroll, click row/day → create with that user, click bar → open, tooltip with time and participants
- [ ] 5.6 Add `components/calendar/ParticipantPicker` (multi-select of active users with colour swatch)
- [ ] 5.7 Add `components/calendar/EventDialog` — create/edit/read-only modes, all-day toggle, date/time pickers, participants defaulting to the current user, optional work selector, client validation, delete with confirmation
- [ ] 5.8 Register `/calendar` route in `App.tsx` and the sidebar entry in `AppSidebar.tsx`
- [ ] 5.9 Add `locales/{it,en}/calendar.json` and the `menu.calendar` key in `navigation.json`; pass the date-fns locale (`it` / `enUS`) to all formatting

## 6. Frontend user colour management

- [ ] 6.1 Add a colour picker (palette swatches + custom hex) to `ProfilePage`
- [ ] 6.2 Show the colour swatch in `UsersPage` and allow ADMIN/OWNER to change it

## 7. Verification

- [ ] 7.1 `npm run lint` and `npm run build` pass; `./mvnw test` passes
- [ ] 7.2 Manual check: create an event for self, for a colleague, and for three people; verify colours in both views, "only mine" in both views, read-only dialog for a non-creator, admin edit of another user's event, navigation across months, Italian and English labels, phone-width layout
