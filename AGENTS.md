# Repository Guidelines

## Project Structure & Module Organization
- `app/`: Flutter client for Android/iOS/Web with screens for rally input, serve tracker, substitutions, and history dashboards mirroring the StatSheet columns (transition, FBK, wins/losses, serve rotations, player attack/block grids).
- **NOTE:** Simplified architecture with no Node.js backend - all processing done locally in Flutter with optional Supabase sync.
- `supabase/`: SQL migrations, Row Level Security policies, and Edge Functions for optional cloud backup and sync.
- `docs/`: UX mocks, spreadsheet references (e.g., `StatSheet.png`), and decision records.
- `ops/`: CI workflows, environment templates, and infrastructure scripts.

## Build, Test, and Development Commands
- `flutter pub get && flutter run -d chrome|ios|android`: install deps and launch the client for the targeted platform.
- `flutter test`: unit/widget test suite for calculators and UI logic.
- `supabase start`: boot local Supabase stack (Postgres, Auth, storage) for optional cloud sync (note: app works fully offline).
- `flutter build apk|web|ios`: build for release.

## Coding Style & Naming Conventions
- Flutter: prefer Dart lints (`flutter_lints`), 2-space indentation, PascalCase widgets, camelCase state hooks/providers, snake_case files (e.g., `serve_tracker_view.dart`).
- Node: Typescript strict mode, ESLint + Prettier, 2-space indent, DTOs in PascalCase, handlers in camelCase.
- SQL: lowercase table and column names (`match_stats`, `first_ball_kills`).
- Commit to shared enums/IDs for stat types (e.g., `TransitionPoint`, `OppFBK`).

## Testing Guidelines
- Client: golden/widget tests for rotation flows and offline caching; mock Supabase to verify sync queues.
- Server: integration tests against a test DB to validate set/match rollups, win/loss deltas, and concurrency handling.
- Minimum 80% coverage on calculation modules; add regression tests before touching schema or stat logic.
- Name tests after stat scenario (`describe('firstBallKillTracker')`).

## Commit & Pull Request Guidelines
- Commit messages follow "type(scope): summary" (e.g., `feat(app): add serve rotation grid`). Keep changes scoped to one feature or fix.
- PRs must include: context, screenshots/recording for UI, affected stat categories, and test evidence (`flutter test`, `npm test`).
- Link tracking issue or roadmap item; flag migrations or breaking API changes in the description.

## Architecture & Initial Plan
1. Define Supabase schema: matches, sets, rallies, players, actions (transition, FBK, serves, subs, timeouts, attacks, blocks) plus sync metadata.
2. Scaffold Flutter app with offline-first store (Drift/Hive) and screens that replicate the StatSheet layout for quick tap entry.
3. Build Node service for derived stats, exports, and season aggregations; integrate with Supabase functions or triggers for rollups.
4. Add history dashboards (set → match → season) and CSV/PDF export parity with the coach’s sheet.
5. Harden offline sync, conflict resolution, and add CI (lint, tests, formatting, schema drift checks).
