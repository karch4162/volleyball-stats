import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../match_setup/data/data.dart';
import '../match_setup/constants.dart';
import '../match_setup/models/match_draft.dart';
import '../match_setup/models/match_player.dart';
import '../match_setup/providers.dart';

class RallyCaptureState {
  RallyCaptureState({
    required this.draft,
    required this.roster,
  });

  final MatchDraft draft;
  final List<MatchPlayer> roster;
}

final rallyCaptureStateProvider = FutureProvider.family<RallyCaptureState, String>((ref, matchId) async {
  final repository = ref.watch(matchSetupRepositoryProvider);
  final draft = await repository.loadDraft(matchId: matchId);
  if (draft == null) {
    throw StateError('No draft found for match $matchId');
  }
  final roster = await repository.fetchRoster(teamId: defaultTeamId);
  return RallyCaptureState(draft: draft, roster: roster);
});

