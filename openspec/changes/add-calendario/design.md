## Context

AtixOps has users of three types (TECHNICIAN, ADMINISTRATION, SELLER) in a `SINGLE_TABLE` hierarchy (`entities/users/User.java`), soft-deleted via `deletedAt`. Work orders already relate users through `WorkAssignment` (`work_assignments`, unique on `work_id, user_id`) and carry an `expectedStartDate`, but there is no time-slot concept anywhere: nothing records *when* a person is busy.

Constraints from the current codebase:

1. **No migration tool** — `ddl-auto = update`. All schema work must be additive.
2. **Timestamps are `LocalDateTime`** everywhere (`User.deletedAt`, `Work.statusChangedAt`, `WorkAssignment.assignedAt`); the team works in a single time zone (Europe/Rome).
3. **Frontend has no calendar library**: only `date-fns` 3, `react-day-picker` 8 (date picker) and `recharts`. UI is shadcn + Tailwind; server state is React Query; i18n is per-namespace JSON in `locales/{it,en}`.
4. **Role model**: `UserRole` USER / ADMIN / OWNER; the existing services already gate admin operations on ADMIN/OWNER.

## Goals / Non-Goals

**Goals:**

- One shared team calendar: every user sees all commitments, creates them for any set of colleagues.
- Each user is recognisable by a stable colour in both views.
- Two views over the same range-query API: month grid and per-user Gantt.
- "Only mine" filtering that is cheap server-side and consistent across views.
- Additive schema only; no new npm dependency.

**Non-Goals:**

- Recurrence, reminders, notifications, invitations with RSVP.
- External calendar sync / iCal.
- Private or confidential events.
- Drag-and-drop move/resize (possible follow-up; see Open Questions).
- Conflict detection.

## Decisions

### D1 — `CalendarEvent` with a `@ManyToMany` participant set

`calendar_events` (id UUID, title, description, location, start_at, end_at, all_day, work_id nullable FK, created_by FK not null, created_at, updated_at) and a join table `calendar_event_participants (event_id, user_id)` with a composite primary key.

*Rationale.* Participants carry no per-person attributes in this change (no RSVP, no role), so a plain join table is enough and maps to a `Set<User>` with `@ManyToMany`. One event row for a group commitment means a single edit moves everyone.

*Alternatives.* An explicit `CalendarEventParticipant` entity (like `WorkAssignment`) — deferred until RSVP/status per participant is needed; the table shape is compatible, so it can be promoted later without data migration. One event row per participant — rejected: group edits would require fan-out and could drift.

### D2 — Creator is not implicitly a participant

The creator is stored separately (`created_by`) and is a participant only if chosen. The dialog defaults the participant list to the current user, so the common case stays one click, while "I'm booking this for Luca" does not pollute the creator's own calendar or the "only mine" filter.

### D3 — Half-open intervals stored as `LocalDateTime`

Events are `[start_at, end_at)`. All-day events are normalised to midnight boundaries (end = day after last day). Overlap query: `start_at < :to AND end_at > :from`.

*Rationale.* Half-open intervals make all-day and multi-day handling uniform and avoid off-by-one at midnight. `LocalDateTime` matches every other timestamp in the codebase and the single-time-zone operation. An index on `(start_at, end_at)` supports the range query.

*Alternatives.* `OffsetDateTime`/`Instant` — more correct across zones but inconsistent with the rest of the model and with no current need. Revisit if the team spans zones.

### D4 — Query with JPA Specification, bounded window

`GET /calendar-events?from&to[&mine][&participantIds]` built with `CalendarEventSpecification` (overlap, `mine` → join participants on caller id, participants → `IN`), `distinct` to avoid duplicates from the join, participants fetched with an entity graph to avoid N+1. Window capped at 100 days (Gantt month ≈ 31 days, month grid ≈ 42 days) so a single request is always small; no pagination.

*Alternatives.* Pagination — rejected: a calendar needs the whole window at once. GraphQL resolver — not needed; the frontend uses REST for every other page.

### D5 — Colour stored on `User`, assigned from a palette

Nullable column `users.calendar_color` (`#RRGGBB`). `UserColorService.pickColor()` returns the palette entry with the fewest active users; called on user creation and by an idempotent `ApplicationRunner` that backfills users with `null` colour (same pattern as the existing admin/checklist bootstrap runners). Palette: 12–16 colours chosen to be distinguishable and to keep white text readable (contrast ≥ 4.5:1); the frontend computes text colour (black/white) from luminance anyway, so user-chosen colours stay readable.

Endpoints: `PATCH /users/me/calendar-color` (self) and `PATCH /users/{id}/calendar-color` (ADMIN/OWNER).

*Alternatives.* Colour derived from a hash of the user id — rejected: not editable, collisions likely. Colour on a separate preferences table — overkill for one field.

### D6 — Permissions in the service layer

`CalendarEventService` checks edit/delete as `creator == caller || role ∈ {ADMIN, OWNER}` and returns `canEdit` on each DTO so the UI never re-implements the rule. Reads are open to every authenticated user (D-shared visibility is a product decision, see proposal).

### D7 — Views built in-house on `date-fns` + Tailwind

- **Month view**: grid from `startOfWeek(startOfMonth, {weekStartsOn: 1})` to `endOfWeek(endOfMonth)`; events bucketed per day client-side. Chip colouring: single participant → solid background; multiple → a left stripe split into N equal segments (or small dots on narrow screens) plus neutral background.
- **Gantt view**: CSS grid with a sticky first column (user name + swatch) and one column per day. Each event yields one bar per participant row; horizontal position = `(start − rangeStart) / rangeLength`, clamped to the visible range, with partial-day precision for timed events. Lane packing per row via a greedy interval-partitioning pass (sort by start, place in first lane whose last end ≤ start). Horizontal scroll on narrow screens.
- Shared state in `CalendarPage`: `view`, `anchorDate`, `ganttSpan`, `onlyMine`, `participantIds`; the visible range is derived from them and is the React Query key, so both views reuse the cache.
- `view` and `onlyMine` persisted in `localStorage`.

*Alternatives.* FullCalendar — its month view is fine but the per-resource timeline (Gantt by user) is a premium plugin; `react-big-calendar` — no resource timeline either; `gantt-task-react`/`frappe-gantt` — task-oriented (dependencies, progress) rather than people-oriented, and would add two libraries with different styling. A custom implementation is a few hundred lines and matches shadcn styling.

### D8 — Optional link to `Work`

`work_id` nullable FK; the DTO returns `workId` and a short label (order number + client) so events can link to `/works/:id`. Deleting a work order SHALL NOT delete events; the service nulls the reference (or the FK is `ON DELETE SET NULL`) — works are currently not hard-deleted, so this is a safety net.

## Risks / Trade-offs

- [Everyone sees everything, including personal commitments] → Product decision for a small team; users are told titles are visible to all. Private events are a listed non-goal and can be added later with a `visibility` column.
- [Gantt with many users becomes tall] → Participant filter and "only mine"; rows virtualised only if the user count grows well beyond current size.
- [Colour collisions after palette exhaustion] → Names are always shown next to colours (legend, Gantt row header, tooltip); colours are editable.
- [`LocalDateTime` ambiguity across DST changes] → Acceptable for single-zone use; documented in D3.
- [`ddl-auto = update` creates the join table PK and indexes implicitly] → Verify generated DDL on a scratch DB before deploy (task 1.x).
- [N+1 when loading participants] → Entity graph / fetch join in the list query; covered by a repository test.

## Migration Plan

1. Deploy backend: Hibernate adds `calendar_events`, `calendar_event_participants`, `users.calendar_color`. The colour backfill runner assigns colours on first start.
2. Deploy frontend with the new route and sidebar entry.
3. Rollback: redeploy previous versions; new tables and column are ignored by old code. Drop them manually only if the feature is abandoned.

## Open Questions

- Should participants (not only the creator) be allowed to edit or at least remove themselves from an event? Current spec: no.
- Should SELLER / ADMINISTRATION users appear in the Gantt by default, or only TECHNICIANs? Current spec: all active users, filterable.
- Should events linked to a work order also appear inside `WorkDetailPage`? Not in this change.
- Drag-and-drop to move/resize bars in Gantt — follow-up change.
