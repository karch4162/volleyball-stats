-- RLS setup for single-coach tenancy.

-- Teams gain a coach scope for row-level security checks.
alter table teams
  add column if not exists coach_id uuid;

alter table teams
  alter column coach_id set not null;

create index if not exists teams_coach_idx
  on teams (coach_id);

-- Enable row level security on all stat tables.
alter table teams enable row level security;
alter table players enable row level security;
alter table matches enable row level security;
alter table sets enable row level security;
alter table rallies enable row level security;
alter table actions enable row level security;
alter table serve_rotations enable row level security;
alter table substitutions enable row level security;
alter table timeouts enable row level security;
alter table season_totals enable row level security;

-- Teams policies
create policy "coaches_manage_teams"
  on teams
  using (coach_id = auth.uid())
  with check (coach_id = auth.uid());

-- Players policies
create policy "coaches_manage_players"
  on players
  using (
    exists (
      select 1
      from teams t
      where t.id = players.team_id
        and t.coach_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from teams t
      where t.id = players.team_id
        and t.coach_id = auth.uid()
    )
  );

-- Matches policies
create policy "coaches_manage_matches"
  on matches
  using (
    exists (
      select 1
      from teams t
      where t.id = matches.team_id
        and t.coach_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from teams t
      where t.id = matches.team_id
        and t.coach_id = auth.uid()
    )
  );

-- Sets policies
create policy "coaches_manage_sets"
  on sets
  using (
    exists (
      select 1
      from matches m
      join teams t on t.id = m.team_id
      where m.id = sets.match_id
        and t.coach_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from matches m
      join teams t on t.id = m.team_id
      where m.id = sets.match_id
        and t.coach_id = auth.uid()
    )
  );

-- Rallies policies
create policy "coaches_manage_rallies"
  on rallies
  using (
    exists (
      select 1
      from sets s
      join matches m on m.id = s.match_id
      join teams t on t.id = m.team_id
      where s.id = rallies.set_id
        and t.coach_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from sets s
      join matches m on m.id = s.match_id
      join teams t on t.id = m.team_id
      where s.id = rallies.set_id
        and t.coach_id = auth.uid()
    )
  );

-- Actions policies
create policy "coaches_manage_actions"
  on actions
  using (
    exists (
      select 1
      from rallies r
      join sets s on s.id = r.set_id
      join matches m on m.id = s.match_id
      join teams t on t.id = m.team_id
      where r.id = actions.rally_id
        and t.coach_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from rallies r
      join sets s on s.id = r.set_id
      join matches m on m.id = s.match_id
      join teams t on t.id = m.team_id
      where r.id = actions.rally_id
        and t.coach_id = auth.uid()
    )
  );

-- Serve rotations policies
create policy "coaches_manage_serve_rotations"
  on serve_rotations
  using (
    exists (
      select 1
      from sets s
      join matches m on m.id = s.match_id
      join teams t on t.id = m.team_id
      where s.id = serve_rotations.set_id
        and t.coach_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from sets s
      join matches m on m.id = s.match_id
      join teams t on t.id = m.team_id
      where s.id = serve_rotations.set_id
        and t.coach_id = auth.uid()
    )
  );

-- Substitutions policies
create policy "coaches_manage_substitutions"
  on substitutions
  using (
    exists (
      select 1
      from sets s
      join matches m on m.id = s.match_id
      join teams t on t.id = m.team_id
      where s.id = substitutions.set_id
        and t.coach_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from sets s
      join matches m on m.id = s.match_id
      join teams t on t.id = m.team_id
      where s.id = substitutions.set_id
        and t.coach_id = auth.uid()
    )
  );

-- Timeouts policies
create policy "coaches_manage_timeouts"
  on timeouts
  using (
    exists (
      select 1
      from sets s
      join matches m on m.id = s.match_id
      join teams t on t.id = m.team_id
      where s.id = timeouts.set_id
        and t.coach_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from sets s
      join matches m on m.id = s.match_id
      join teams t on t.id = m.team_id
      where s.id = timeouts.set_id
        and t.coach_id = auth.uid()
    )
  );

-- Season totals policies
create policy "coaches_manage_season_totals"
  on season_totals
  using (
    exists (
      select 1
      from teams t
      where t.id = season_totals.team_id
        and t.coach_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from teams t
      where t.id = season_totals.team_id
        and t.coach_id = auth.uid()
    )
  );

