import 'dart:async';

import '../models/match_draft.dart';
import '../models/match_player.dart';
import 'match_setup_repository.dart';

class InMemoryMatchSetupRepository implements MatchSetupRepository {
  InMemoryMatchSetupRepository({
    List<MatchPlayer>? seedRoster,
    Map<String, MatchDraft>? seedDrafts,
  })  : _roster = seedRoster ?? _defaultRoster,
        _drafts = seedDrafts ?? <String, MatchDraft>{};

  final List<MatchPlayer> _roster;
  final Map<String, MatchDraft> _drafts;

  static final List<MatchPlayer> _defaultRoster = [
    const MatchPlayer(
      id: 'player-avery',
      name: 'Avery Harper',
      jerseyNumber: 2,
      position: 'Setter',
    ),
    const MatchPlayer(
      id: 'player-bailey',
      name: 'Bailey Jordan',
      jerseyNumber: 5,
      position: 'Opposite',
    ),
    const MatchPlayer(
      id: 'player-casey',
      name: 'Casey Lane',
      jerseyNumber: 11,
      position: 'Outside Hitter',
    ),
    const MatchPlayer(
      id: 'player-devon',
      name: 'Devon Cruz',
      jerseyNumber: 9,
      position: 'Middle Blocker',
    ),
    const MatchPlayer(
      id: 'player-elliot',
      name: 'Elliot Kim',
      jerseyNumber: 4,
      position: 'Libero',
    ),
    const MatchPlayer(
      id: 'player-finley',
      name: 'Finley Brooks',
      jerseyNumber: 7,
      position: 'Middle Blocker',
    ),
    const MatchPlayer(
      id: 'player-greer',
      name: 'Greer Miles',
      jerseyNumber: 10,
      position: 'Outside Hitter',
    ),
  ];

  @override
  Future<List<MatchPlayer>> fetchRoster({required String teamId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _roster;
  }

  @override
  Future<MatchDraft?> loadDraft({required String matchId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _drafts[matchId];
  }

  @override
  Future<void> saveDraft({
    required String teamId,
    required String matchId,
    required MatchDraft draft,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _drafts[matchId] = draft;
  }
}

