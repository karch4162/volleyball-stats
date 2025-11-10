import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:volleyball_stats_app/features/match_setup/constants.dart';
import 'package:volleyball_stats_app/features/match_setup/data/data.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_draft.dart';

void main() {
  final url = Platform.environment['SUPABASE_URL'];
  final serviceRoleKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];

  if (url == null || serviceRoleKey == null) {
    test(
      'Supabase repository integration tests skipped',
      () {},
      skip:
          'Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables to run integration tests.',
    );
    return;
  }

  late SupabaseClient client;
  late InMemoryMatchDraftCache cache;
  late CachedMatchSetupRepository repository;

  setUpAll(() {
    client = SupabaseClient(url, serviceRoleKey);
    cache = InMemoryMatchDraftCache();
    repository = CachedMatchSetupRepository(
      primary: SupabaseMatchSetupRepository(client, teamId: defaultTeamId),
      cache: cache,
      teamId: defaultTeamId,
    );
  });

  test('fetchRoster returns seeded players', () async {
    final roster = await repository.fetchRoster(teamId: defaultTeamId);
    expect(roster.length, greaterThanOrEqualTo(6));
  });

  test('loadDraft returns seeded match draft', () async {
    final draft = await repository.loadDraft(matchId: defaultMatchDraftId);
    expect(draft, isNotNull);
    expect(draft!.opponent.isNotEmpty, isTrue);
    expect(draft.selectedPlayerIds, isNotEmpty);
  });

  test('saveDraft persists to Supabase and cache', () async {
    final matchId = const Uuid().v4();
    final roster = await repository.fetchRoster(teamId: defaultTeamId);
    final selectedPlayers = roster.take(6).toList();

    final draft = MatchDraft(
      opponent: 'Integration Opponent',
      matchDate: DateTime.now().toUtc(),
      location: 'Home',
      seasonLabel: '2025',
      selectedPlayerIds: selectedPlayers.map((p) => p.id).toSet(),
      startingRotation: {
        for (var i = 0; i < selectedPlayers.length; i++)
          i + 1: selectedPlayers[i].id,
      },
    );

    await client.from('matches').insert({
      'id': matchId,
      'team_id': defaultTeamId,
      'opponent': 'Integration Opponent',
      'match_date': DateTime.now().toIso8601String(),
      'season_label': '2025',
      'location': 'Home',
    });

    addTearDown(() async {
      await cache.clear(matchId);
      await client.from('match_drafts').delete().eq('match_id', matchId);
      await client.from('matches').delete().eq('id', matchId);
    });

    await repository.saveDraft(
      teamId: defaultTeamId,
      matchId: matchId,
      draft: draft,
    );

    final remoteDraft = await client
        .from('match_drafts')
        .select()
        .eq('match_id', matchId)
        .maybeSingle() as Map<String, dynamic>?;
    expect(remoteDraft, isNotNull);
    expect(remoteDraft!['opponent'], equals('Integration Opponent'));

    final cachedDraft = await cache.load(matchId);
    expect(cachedDraft, isNotNull);
    expect(cachedDraft!.opponent, equals('Integration Opponent'));

    await client.from('match_drafts').delete().eq('match_id', matchId);

    final loadedFromCache = await repository.loadDraft(matchId: matchId);
    expect(loadedFromCache, isNotNull);
    expect(loadedFromCache!.opponent, equals('Integration Opponent'));
  });
}

