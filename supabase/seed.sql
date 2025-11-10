begin;

-- Coach profile placeholders derived from pgTAP tests.
-- These UUIDs should match Supabase auth user IDs used during development.
with upserted_team as (
  insert into teams (id, name, level, season_label, coach_id)
  values (
    '11111111-1111-1111-1111-111111111111',
    'Alpha Wildcats',
    'Varsity',
    '2025',
    '00000000-0000-0000-0000-000000000001'
  )
  on conflict (id) do update
    set name = excluded.name,
        level = excluded.level,
        season_label = excluded.season_label,
        coach_id = excluded.coach_id
  returning id
)
insert into players (id, team_id, jersey_number, first_name, last_name, position, active)
values
  (
    '21111111-1111-1111-1111-111111111111',
    (select id from upserted_team),
    2,
    'Avery',
    'Setter',
    'S',
    true
  ),
  (
    '22111111-1111-1111-1111-111111111111',
    (select id from upserted_team),
    5,
    'Bailey',
    'Opp',
    'OPP',
    true
  ),
  (
    '23111111-1111-1111-1111-111111111111',
    (select id from upserted_team),
    11,
    'Casey',
    'OH',
    'OH',
    true
  ),
  (
    '24111111-1111-1111-1111-111111111111',
    (select id from upserted_team),
    9,
    'Devon',
    'Cruz',
    'MB',
    true
  ),
  (
    '25111111-1111-1111-1111-111111111111',
    (select id from upserted_team),
    4,
    'Elliot',
    'Kim',
    'L',
    true
  ),
  (
    '26111111-1111-1111-1111-111111111111',
    (select id from upserted_team),
    7,
    'Finley',
    'Brooks',
    'MB',
    true
  ),
  (
    '27111111-1111-1111-1111-111111111111',
    (select id from upserted_team),
    10,
    'Greer',
    'Miles',
    'OH',
    true
  )
on conflict (id) do update
  set team_id = excluded.team_id,
      jersey_number = excluded.jersey_number,
      first_name = excluded.first_name,
      last_name = excluded.last_name,
      position = excluded.position,
      active = excluded.active;

with upserted_match as (
  insert into matches (id, team_id, opponent, match_date, location, season_label, notes)
  values (
    '31111111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111',
    'Ridgeview Hawks',
    current_date - interval '3 day',
    'Home',
    '2025',
    'Sample StatSheet scenario'
  )
  on conflict (id) do update
    set opponent = excluded.opponent,
        match_date = excluded.match_date,
        location = excluded.location,
        season_label = excluded.season_label,
        notes = excluded.notes
  returning id
)
insert into sets (id, match_id, set_number, result, start_time, end_time)
values (
  '41111111-1111-1111-1111-111111111111',
  (select id from upserted_match),
  1,
  'win',
  now() - interval '2 hour',
  now() - interval '1 hour 35 minutes'
)
on conflict (id) do update
  set match_id = excluded.match_id,
      set_number = excluded.set_number,
      result = excluded.result,
      start_time = excluded.start_time,
      end_time = excluded.end_time;

insert into rallies (id, set_id, rally_number, rotation, result, transition_type)
values
  (
    '51111111-1111-1111-1111-111111111111',
    '41111111-1111-1111-1111-111111111111',
    1,
    1,
    'win',
    'serve_receive'
  ),
  (
    '52111111-1111-1111-1111-111111111111',
    '41111111-1111-1111-1111-111111111111',
    2,
    1,
    'loss',
    'transition'
  ),
  (
    '53111111-1111-1111-1111-111111111111',
    '41111111-1111-1111-1111-111111111111',
    3,
    2,
    'win',
    'first_ball_kill'
  )
on conflict (id) do update
  set rally_number = excluded.rally_number,
      rotation = excluded.rotation,
      result = excluded.result,
      transition_type = excluded.transition_type;

insert into actions (id, rally_id, player_id, action_type, action_subtype, outcome, sequence, metadata)
values
  (
    '61111111-1111-1111-1111-111111111111',
    '51111111-1111-1111-1111-111111111111',
    '21111111-1111-1111-1111-111111111111',
    'set',
    'assist',
    'positive',
    1,
    '{"note":"perfect pass to quick"}'
  ),
  (
    '62111111-1111-1111-1111-111111111111',
    '51111111-1111-1111-1111-111111111111',
    '23111111-1111-1111-1111-111111111111',
    'attack',
    'kill',
    'point',
    2,
    '{"swing_zone":"4","stat_block":"transition"}'
  ),
  (
    '63111111-1111-1111-1111-111111111111',
    '52111111-1111-1111-1111-111111111111',
    '22111111-1111-1111-1111-111111111111',
    'serve',
    'error',
    'loss',
    1,
    '{"serve_rotation":1}'
  ),
  (
    '64111111-1111-1111-1111-111111111111',
    '53111111-1111-1111-1111-111111111111',
    '23111111-1111-1111-1111-111111111111',
    'attack',
    'kill',
    'point',
    1,
    '{"stat_block":"fbk"}'
  )
on conflict (id) do update
  set rally_id = excluded.rally_id,
      player_id = excluded.player_id,
      action_type = excluded.action_type,
      action_subtype = excluded.action_subtype,
      outcome = excluded.outcome,
      sequence = excluded.sequence,
      metadata = excluded.metadata;

insert into serve_rotations (id, set_id, rotation, attempt_number, server_id, outcome, notes)
values
  (
    '71111111-1111-1111-1111-111111111111',
    '41111111-1111-1111-1111-111111111111',
    1,
    1,
    '22111111-1111-1111-1111-111111111111',
    'error',
    'Sailed long on second rally'
  ),
  (
    '72111111-1111-1111-1111-111111111111',
    '41111111-1111-1111-1111-111111111111',
    2,
    1,
    '23111111-1111-1111-1111-111111111111',
    'ace',
    'Closed set with FBK ace'
  )
on conflict (id) do update
  set rotation = excluded.rotation,
      attempt_number = excluded.attempt_number,
      server_id = excluded.server_id,
      outcome = excluded.outcome,
      notes = excluded.notes;

insert into season_totals (id, team_id, player_id, season_label, stats)
values
  (
    '81111111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111',
    '23111111-1111-1111-1111-111111111111',
    '2025',
    '{"kills":2,"attempts":2,"fbk":1,"serve_aces":1,"serve_errors":0}'
  ),
  (
    '82111111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111',
    '22111111-1111-1111-1111-111111111111',
    '2025',
    '{"serve_aces":0,"serve_errors":1}'
  ),
  (
    '83111111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111',
    '21111111-1111-1111-1111-111111111111',
    '2025',
    '{"assists":1,"digs":0}'
  )
on conflict (id) do update
  set stats = excluded.stats,
      updated_at = now();

insert into match_drafts (team_id, match_id, opponent, match_date, location, season_label, selected_player_ids, starting_rotation)
values (
  '11111111-1111-1111-1111-111111111111',
  '31111111-1111-1111-1111-111111111111',
  'Ridgeview Hawks',
  current_date - interval '3 day',
  'Home',
  '2025',
  array[
    '21111111-1111-1111-1111-111111111111',
    '22111111-1111-1111-1111-111111111111',
    '23111111-1111-1111-1111-111111111111',
    '24111111-1111-1111-1111-111111111111',
    '25111111-1111-1111-1111-111111111111',
    '26111111-1111-1111-1111-111111111111'
  ],
  '{
    "1": "21111111-1111-1111-1111-111111111111",
    "2": "22111111-1111-1111-1111-111111111111",
    "3": "23111111-1111-1111-1111-111111111111",
    "4": "24111111-1111-1111-1111-111111111111",
    "5": "25111111-1111-1111-1111-111111111111",
    "6": "26111111-1111-1111-1111-111111111111"
  }'::jsonb
)
on conflict (team_id, match_id) do update
  set opponent = excluded.opponent,
      match_date = excluded.match_date,
      location = excluded.location,
      season_label = excluded.season_label,
      selected_player_ids = excluded.selected_player_ids,
      starting_rotation = excluded.starting_rotation,
      updated_at = now();

commit;

