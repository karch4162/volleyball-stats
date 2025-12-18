# Flutter Match Setup Plan (Phase 1)

## Objectives
- Provide coach-friendly flow to capture match metadata, roster, and initial rotations before rally capture.
- Ensure data persists offline using chosen local store (Drift/Hive) and syncs with Supabase when online.

## Proposed Flow
1. **Landing / Dashboard**
   - Lists recent matches (local cache) with quick actions (`Continue`, `View History`).
   - CTA: `Start New Match`.
2. **Match Metadata Screen**
   - Fields: opponent, match date/time, location, best-of (3/5), season label selector.
   - Persist to local store immediately using optimistic IDs.
3. **Roster Selection**
   - Pulls existing team roster; toggle players active for the match.
   - Inline add player (name, jersey, position) with validation.
4. **Set Configuration**
   - Create Set 1 with expected starting rotation (positions 1–6).
   - Optional: pre-define libero assignments.
5. **Confirmation Summary**
   - Display metadata, starters, bench; allow edit before entering rally capture.
   - On confirm, navigate to `rally_capture` with Set 1 context.

## Technical Notes
- Route structure via `go_router`; dedicated `match_setup` feature module in `app/lib/features/match_setup/`.
- Use Riverpod providers for `MatchSetupController` to manage step state; expose immutable data models (freezed).
- Persist via local repository interface (`MatchRepository` with `createMatchDraft`, `updateMatchDraft` methods).
- Prepare mappers between local models and Supabase schema (e.g., `MatchDraft` → `matches`, `sets`, `serve_rotations` seed rows).

## UI Components
- `MatchMetadataForm`: reusable text/date inputs with validation states.
- `RosterSelectionGrid`: jersey-number grid with active state toggles + add button.
- `RotationPicker`: circular layout representing positions 1-6; drag-and-drop optional later.
- `SummaryCard`: aggregated view with edit buttons for each section.

## Open Questions
- Should lineup enforce libero restrictions immediately or allow free-form and validate later?
- How to handle multiple teams per coach (future) in selection step?
- Need design assets? Refer back to `StatSheet.png` for column alignment cues.

## Next Steps
- Scaffold feature directory & empty widgets/controllers.
- Add basic widget tests covering progression through steps with mock repositories.
- Integrate with local storage once entity definitions finalized.

