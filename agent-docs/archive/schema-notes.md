# Supabase Schema Notes

## Overview
- Goal: capture StatSheet parity for match tracking while enabling offline-first sync.
- Entities align with initial migration (`supabase/migrations/0001_init.sql`): teams, players, matches, sets, rallies, actions, serve_rotations, substitutions, timeouts, season_totals.
- All primary keys use `uuid` with `gen_random_uuid()` (requires `pgcrypto` extension).

## Tables
- `teams`: high-level program metadata scoped by `coach_id` (maps to Supabase auth user). Future: support multiple teams per coach.
- `players`: roster entries linked to `teams`. Unique constraint on `(team_id, jersey_number)` avoids duplicates.
- `matches`: opponent/date metadata; `season_label` duplicates for quick filtering before full season tables.
- `sets`: unique per match via `(match_id, set_number)`. `result` constrained to `win|loss|pending`.
- `rallies`: per-set sequences with `rally_number` and rotation to mirror StatSheet row ordering.
- `actions`: fine-grained tap events (attack/block/serve/etc). `metadata` jsonb for extensibility (e.g., attack zone).
- `serve_rotations`: track attempt order per rotation; unique composite ensures deterministic ordering.
- `substitutions` & `timeouts`: optional `rally_id` references allow logging against specific plays.
- `season_totals`: denormalized cache for rollups, keyed by team/player/season.

## Index & Constraint Rationale
- Unique constraints on `(match_id, set_number)` and `(set_id, rally_number)` enforce StatSheet ordering.
- Index on `actions (rally_id, sequence)` supports replay in UI.
- Index on `season_totals (team_id, season_label)` enables team dashboards.
- New `teams_coach_idx` supports RLS joins when filtering by `coach_id`.

## Pending Work
- Normalize enum values (e.g., `result`, `transition_type`, `action_type`) into Postgres enums or lookup tables.
- Add trigger for `season_totals` to update `updated_at` and eventually aggregate stats.
- Incorporate device sync metadata (`created_by`, `source_device_id`, `sync_state`).
- Seed sample data for tests aligning to StatSheet scenarios (transition win, FBK, serve errors, etc.).

## Next Steps
- Validate RLS policies via Supabase CLI tests (insert/select across different auth contexts).
- Extend migration with audit columns (`updated_at`, `deleted_at`) where required for sync conflict resolution.
- Generate Supabase type definitions once CLI is configured.

