# Supabase RLS Policy Plan

> Implemented in `supabase/migrations/0002_rls_policies.sql`; keep this doc updated as rules evolve.

## Goals
- Single-coach tenancy: each authenticated user manages only their own teams, rosters, and stats.
- Allow service role (backend jobs) to bypass RLS for aggregation and exports.
- Keep future multi-coach support in mind by scoping access via `team_members` association.

## Auth Assumptions
- Supabase Auth `auth.users` table supplies `id` GUID per coach.
- Application will map `auth.uid()` to a `coach_id` column stored on `teams`.
- Service key connections (Node backend, Supabase Edge Functions) run with `role = 'service_role'`.

## Tables & Policy Concepts
| Table | Owning Column | Policy Summary |
|-------|---------------|----------------|
| `teams` | `coach_id` (uuid) | Coaches can `select/insert/update/delete` rows where `coach_id = auth.uid()`. |
| `players` | `team_id` | Join against `teams` to ensure membership. |
| `matches` / `sets` | `team_id` | Cascade access via owning team. |
| `rallies`, `actions`, `serve_rotations`, `substitutions`, `timeouts` | `set_id` → `matches.team_id` | Enforce through nested joins using `using (...) with check`. |
| `season_totals` | `team_id` | Read/write limited to owning coach; service role allowed to maintain aggregates. |

## Policy Drafts
1. **Enable RLS** on each table once schema stabilizes.
2. **Teams**:
   ```sql
   alter table teams enable row level security;

   create policy "coaches manage their teams"
     on teams
     using (coach_id = auth.uid())
     with check (coach_id = auth.uid());
   ```
3. **Players & Child Tables**: leverage `exists` guards.
   ```sql
   create policy "manage players for own teams"
     on players
     using (exists (
       select 1 from teams
       where teams.id = players.team_id
         and teams.coach_id = auth.uid()
     ))
     with check (exists (
       select 1 from teams
       where teams.id = players.team_id
         and teams.coach_id = auth.uid()
     ));
   ```
4. Repeat pattern for `matches`, `sets`, `rallies`, `actions`, etc., joining back to `teams`.

## Service Role Considerations
- Policies do not restrict `service_role`. No changes required if using Supabase defaults.
- For Node backend operating with anon key + JWT, include claim `team_ids` for cross-checking if multi-team.

## Future Enhancements
- Introduce `team_members` table for assistants; adjust policies to check membership.
- Add `read-only` policy variant to support observers.
- Consider `deleted_at` soft deletes; policies should filter out soft-deleted rows.

