create or replace function set_current_timestamp_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create table if not exists match_drafts (
  match_id text primary key,
  team_id uuid not null references teams (id) on delete cascade,
  opponent text not null default '',
  match_date date,
  location text not null default '',
  season_label text not null default '',
  selected_player_ids jsonb not null default '[]'::jsonb,
  starting_rotation jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists match_drafts_team_id_idx on match_drafts (team_id);
create index if not exists match_drafts_updated_at_idx on match_drafts (updated_at desc);

create trigger match_drafts_set_updated_at
  before update on match_drafts
  for each row
  execute procedure set_current_timestamp_updated_at();

alter table match_drafts enable row level security;

create policy "coaches_manage_match_drafts"
  on match_drafts
  using (
    exists (
      select 1
      from teams t
      where t.id = match_drafts.team_id
        and t.coach_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from teams t
      where t.id = match_drafts.team_id
        and t.coach_id = auth.uid()
    )
  );

-- Roster Templates table
create table if not exists roster_templates (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams (id) on delete cascade,
  name text not null,
  description text,
  player_ids jsonb not null default '[]'::jsonb,
  default_rotation jsonb not null default '{}'::jsonb,
  use_count integer not null default 0,
  created_at timestamptz not null default now(),
  last_used_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists roster_templates_team_id_idx on roster_templates (team_id);
create index if not exists roster_templates_use_count_idx on roster_templates (team_id, use_count desc, last_used_at desc nulls last);

create trigger roster_templates_set_updated_at
  before update on roster_templates
  for each row
  execute procedure set_current_timestamp_updated_at();

alter table roster_templates enable row level security;

create policy "coaches_manage_roster_templates"
  on roster_templates
  using (
    exists (
      select 1
      from teams t
      where t.id = roster_templates.team_id
        and t.coach_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from teams t
      where t.id = roster_templates.team_id
        and t.coach_id = auth.uid()
    )
  );

