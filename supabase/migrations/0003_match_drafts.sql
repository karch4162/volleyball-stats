create or replace function set_current_timestamp_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create table if not exists match_drafts (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams (id) on delete cascade,
  match_id uuid not null references matches (id) on delete cascade,
  opponent text,
  match_date date,
  location text,
  season_label text,
  selected_player_ids text[] not null default '{}',
  starting_rotation jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (team_id, match_id)
);

create index if not exists match_drafts_match_id_idx on match_drafts (match_id);

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

