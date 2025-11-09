select plan(3);

begin;

set local role authenticated;

-- Authenticated coach context
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);

insert into teams (name, coach_id)
values ('Alpha Test Team', auth.uid())
returning id;
\gset

insert into matches (team_id, opponent, match_date, season_label)
values (:'id', 'Rival High', current_date, '2025');

select set_config('rls.test.team_id', :'id', true);

-- Switch to different coach; should not see other teams
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);

select ok(
  (select count(*) = 0 from teams where id = current_setting('rls.test.team_id')::uuid),
  'Unauthorized coach cannot see other teams'
);

select throws_ok(
  $$
    insert into matches (team_id, opponent, match_date)
    values (current_setting('rls.test.team_id')::uuid, 'Blocked Opponent', current_date);
  $$,
  '42501'
);

-- Switch back to owning coach; ensure data visible
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);

select ok(
  (select count(*) = 1 from matches where team_id = current_setting('rls.test.team_id')::uuid),
  'Owning coach sees their match data'
);

delete from matches where team_id = current_setting('rls.test.team_id')::uuid;
delete from teams where id = current_setting('rls.test.team_id')::uuid;

commit;

select * from finish();
