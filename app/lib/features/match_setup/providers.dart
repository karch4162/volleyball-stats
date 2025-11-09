import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/data.dart';
import 'models/match_player.dart';

const String defaultTeamId = '11111111-1111-1111-1111-111111111111';

final matchSetupRepositoryProvider = Provider<MatchSetupRepository>((ref) {
  return InMemoryMatchSetupRepository();
});

final matchSetupRosterProvider =
    FutureProvider.autoDispose<List<MatchPlayer>>((ref) async {
  final repository = ref.watch(matchSetupRepositoryProvider);
  return repository.fetchRoster(teamId: defaultTeamId);
});

