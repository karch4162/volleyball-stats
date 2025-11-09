-- Initial schema for volleyball stats tracking.
-- This mirrors the high-level entities from StatSheet and the development plan.

create extension if not exists "pgcrypto";

create table if not exists teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  level text,
  season_label text,
  created_at timestamptz not null default now()
);

create table if not exists players (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams (id) on delete cascade,
  jersey_number smallint not null,
  first_name text not null,
  last_name text not null,
  position text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create unique index if not exists players_team_number_idx
  on players (team_id, jersey_number);

create table if not exists matches (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams (id) on delete cascade,
  opponent text not null,
  match_date date not null,
  location text,
  season_label text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists sets (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references matches (id) on delete cascade,
  set_number smallint not null check (set_number > 0),
  result text check (result in ('win', 'loss', 'pending')),
  start_time timestamptz,
  end_time timestamptz,
  created_at timestamptz not null default now(),
  unique (match_id, set_number)
);

create table if not exists rallies (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references sets (id) on delete cascade,
  rally_number integer not null check (rally_number > 0),
  rotation integer check (rotation between 1 and 6),
  result text, -- e.g., win, loss, error, opponent_fbk
  transition_type text, -- e.g., transition, serve_receive, free_ball
  created_at timestamptz not null default now(),
  unique (set_id, rally_number)
);

create index if not exists rallies_set_id_idx on rallies (set_id);

create table if not exists actions (
  id uuid primary key default gen_random_uuid(),
  rally_id uuid not null references rallies (id) on delete cascade,
  player_id uuid references players (id),
  action_type text not null, -- e.g., attack, block, serve, dig
  action_subtype text, -- e.g., kill, error
  outcome text, -- textual outcome for quick filters
  sequence smallint not null default 1,
  metadata jsonb not null default '{}'::jsonb,
  recorded_at timestamptz not null default now()
);

create index if not exists actions_rally_sequence_idx
  on actions (rally_id, sequence);

create table if not exists serve_rotations (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references sets (id) on delete cascade,
  rotation integer not null check (rotation between 1 and 6),
  attempt_number smallint not null check (attempt_number > 0),
  server_id uuid references players (id),
  outcome text, -- e.g., ace, error, in_play
  notes text,
  created_at timestamptz not null default now(),
  unique (set_id, rotation, attempt_number)
);

create table if not exists substitutions (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references sets (id) on delete cascade,
  rally_id uuid references rallies (id),
  player_in uuid not null references players (id),
  player_out uuid not null references players (id),
  reason text,
  created_at timestamptz not null default now()
);

create table if not exists timeouts (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references sets (id) on delete cascade,
  rally_id uuid references rallies (id),
  taken_by text check (taken_by in ('us', 'opponent')),
  reason text,
  created_at timestamptz not null default now()
);

create table if not exists season_totals (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams (id) on delete cascade,
  player_id uuid references players (id),
  season_label text not null,
  stats jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (team_id, player_id, season_label)
);

create index if not exists season_totals_team_idx
  on season_totals (team_id, season_label);

