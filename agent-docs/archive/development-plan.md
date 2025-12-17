# DEVELOPMENT-PLAN

## Phase 0: Environment & Tooling
1. Initialize git repo, configure main branch protections, add base README and AGENTS guidelines.
2. Scaffold folder structure: `app/`, `server/`, `supabase/`, `agent-docs/`, `docs/`, `ops/`.
3. Bootstrap Flutter project inside `app/`; add shared `lib/core` module with constants for stat types.
4. Configure Node.js/TypeScript project in `server/` with ESLint, Prettier, Jest/Vitest.
5. Install Supabase CLI; generate `.env.example`, local docker compose via `supabase start`.
6. Set up CI workflow templates (GitHub/GitLab) running `flutter analyze`, `flutter test`, `npm test`, `supabase db diff`.

## Phase 1: Data Modeling & Supabase Foundation
1. Draft ERD covering teams, players, matches, sets, rallies, actions, serve_rotations, substitutions, timeouts, season_totals.
2. Write initial SQL migrations (`supabase/migrations/0001_init.sql`) to create core tables with constraints and indexes.
3. Implement Supabase Row Level Security for single coach context; seed roles and policies.
4. Add Edge Function skeleton `actions-rollup.ts` for stat aggregation triggers.
5. Validate schema locally with sample data + psql queries mirroring StatSheet totals; document in `docs/schema-notes.md`.

## Phase 2: Flutter App Scaffolding
1. Implement global app state (Riverpod/Bloc) and routing (`go_router`) with placeholders for Match Setup, Rally Capture, Serve Tracker, Player Stats, History.
2. Build `match_setup` flow: team roster input, match metadata, set creation; persist to local store (Drift/Hive).
3. Create UI components reproducing StatSheet groupings but optimized for taps (transition grid, FBK toggles, serve rotation rows, player attack/block matrix).
4. Implement substitution and timeout dialogs with undo and validation against rotation rules.
5. Add local cache encryption option and data export to JSON for debugging.

## Phase 3: Offline Store & Sync Queue
1. Design local entities mirroring Supabase schema; add DAO layer with pending sync flags.
2. Build action queue that records every tap with timestamp, device ID, and optimistic IDs.
3. Integrate connectivity monitoring; when online, batch push queued actions to Supabase via RPC/REST.
4. Handle server acknowledgements, mark local entries as synced, and reconcile conflicts (e.g., duplicate rally numbers).
5. Add instrumentation/logging for sync attempts and failures (Sentry breadcrumbs).

## Phase 4: Node.js Service & Aggregations
1. Implement `/matches`, `/sets`, `/rallies`, `/actions` endpoints with validation and Supabase service key auth.
2. Create aggregation jobs (BullMQ/cron) to recompute match/set/season totals and verify against incoming actions.
3. Add PDF/CSV generators mirroring StatSheet columns using templates (Puppeteer/PDFKit) plus storage upload.
4. Provide analytics endpoints (transition %, serve efficiency, attack/block leaders) consumed by the app.
5. Write integration tests hitting a test Postgres DB seeded via Supabase migration snapshot.

## Phase 5: Insights UI & Reporting
1. Implement live set dashboard displaying transition/FBK counts, points won/lost, serve summaries by rotation.
2. Build match recap view with per-player attack/block stats and export buttons (CSV/PDF share sheet).
3. Create season dashboard aggregating multiple matches with filters (opponent, date range) and charts.
4. Add notifications/cues when data diverges from expected totals (e.g., missing rally entries).

## Phase 6: QA, Beta, and Release Prep
1. Expand automated tests (widget, golden, integration) to cover all critical flows; target 80%+ coverage on stat logic.
2. Run manual smoke tests across Android/iOS/web, including offline scenarios and sync recovery.
3. Set up monitoring (Sentry, Supabase logs) and crash reporting.
4. Prepare onboarding documentation, beta instructions, and release notes; publish via TestFlight/Play Internal and host PWA build.
5. Plan backlog for multi-user support and advanced analytics based on coach feedback.

## Tracking & Progress Rituals
- Use GitHub Projects/Kanban with columns per phase; each numbered task becomes a ticket referencing this plan.
- Update `agent-docs/STATUS.md` (to be created) after each milestone with outcomes, blockers, and next actions.
- During development sprints, demo completed flows to validate the StatSheet requirements before moving forward.
