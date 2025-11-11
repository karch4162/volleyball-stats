import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../match_setup/data/data.dart';
import '../match_setup/constants.dart';
import '../match_setup/models/match_draft.dart';
import '../match_setup/models/match_player.dart';
import '../match_setup/providers.dart';

class RallyCaptureState {
  RallyCaptureState({
    required this.draft,
    required this.activePlayers,
    required this.benchPlayers,
    required this.rotation,
  });

  final MatchDraft draft;
  final List<MatchPlayer> activePlayers;
  final List<MatchPlayer> benchPlayers;
  final Map<int, MatchPlayer?> rotation;
}

MatchPlayer? _findPlayerById(List<MatchPlayer> roster, String id) {
  try {
    return roster.firstWhere((player) => player.id == id);
  } catch (_) {
    return null;
  }
}

final rallyCaptureStateProvider =
    FutureProvider.family<RallyCaptureState, String>((ref, matchId) async {
  final repository = ref.watch(matchSetupRepositoryProvider);
  final draft = await repository.loadDraft(matchId: matchId);
  if (draft == null) {
    throw StateError('No draft found for match $matchId');
  }
  final roster = await repository.fetchRoster(teamId: defaultTeamId);
  final active = roster
      .where((player) => draft.selectedPlayerIds.contains(player.id))
      .toList(growable: false);
  final bench = roster
      .where((player) => !draft.selectedPlayerIds.contains(player.id))
      .toList(growable: false);
  final rotation = <int, MatchPlayer?>{};
  draft.startingRotation.forEach((pos, playerId) {
    rotation[pos] = _findPlayerById(roster, playerId);
  });
  return RallyCaptureState(
    draft: draft,
    activePlayers: active,
    benchPlayers: bench,
    rotation: rotation,
  );
});

