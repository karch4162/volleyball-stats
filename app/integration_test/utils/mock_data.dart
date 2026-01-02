import 'package:volleyball_stats_app/features/match_setup/models/match_draft.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_player.dart';
import 'package:volleyball_stats_app/features/teams/models/team.dart';

/// Creates a mock Team object for testing
Team createMockTeam({
  String? id,
  String? name,
  String? level,
  String? seasonLabel,
  String? coachId,
}) {
  return Team(
    id: id ?? 'team-test-001',
    name: name ?? 'Thunderbolts Volleyball',
    level: level ?? 'Varsity',
    seasonLabel: seasonLabel ?? 'Spring 2026',
    coachId: coachId ?? 'coach-test-001',
  );
}

/// Creates a mock MatchPlayer object for testing
MatchPlayer createMockPlayer({
  String? id,
  String? name,
  int? jerseyNumber,
  String? position,
}) {
  return MatchPlayer(
    id: id ?? 'player-test-001',
    name: name ?? 'Sarah Johnson',
    jerseyNumber: jerseyNumber ?? 7,
    position: position ?? 'Outside Hitter',
  );
}

/// Creates a list of mock players representing a full roster
List<MatchPlayer> createMockRoster() {
  return [
    const MatchPlayer(
      id: 'player-001',
      name: 'Sarah Johnson',
      jerseyNumber: 1,
      position: 'Setter',
    ),
    const MatchPlayer(
      id: 'player-002',
      name: 'Emily Davis',
      jerseyNumber: 2,
      position: 'Libero',
    ),
    const MatchPlayer(
      id: 'player-003',
      name: 'Jessica Martinez',
      jerseyNumber: 3,
      position: 'Outside Hitter',
    ),
    const MatchPlayer(
      id: 'player-004',
      name: 'Ashley Wilson',
      jerseyNumber: 4,
      position: 'Outside Hitter',
    ),
    const MatchPlayer(
      id: 'player-005',
      name: 'Amanda Brown',
      jerseyNumber: 5,
      position: 'Middle Blocker',
    ),
    const MatchPlayer(
      id: 'player-006',
      name: 'Nicole Garcia',
      jerseyNumber: 6,
      position: 'Middle Blocker',
    ),
    const MatchPlayer(
      id: 'player-007',
      name: 'Rachel Lee',
      jerseyNumber: 7,
      position: 'Opposite Hitter',
    ),
    const MatchPlayer(
      id: 'player-008',
      name: 'Megan Thompson',
      jerseyNumber: 8,
      position: 'Setter',
    ),
    const MatchPlayer(
      id: 'player-009',
      name: 'Brittany Anderson',
      jerseyNumber: 9,
      position: 'Defensive Specialist',
    ),
    const MatchPlayer(
      id: 'player-010',
      name: 'Lauren Taylor',
      jerseyNumber: 10,
      position: 'Outside Hitter',
    ),
    const MatchPlayer(
      id: 'player-011',
      name: 'Kayla Moore',
      jerseyNumber: 11,
      position: 'Middle Blocker',
    ),
    const MatchPlayer(
      id: 'player-012',
      name: 'Stephanie White',
      jerseyNumber: 12,
      position: 'Defensive Specialist',
    ),
  ];
}

/// Creates a mock MatchDraft object for testing
MatchDraft createMockMatch({
  String? opponent,
  DateTime? matchDate,
  String? location,
  String? seasonLabel,
  Set<String>? selectedPlayerIds,
  Map<int, String>? startingRotation,
}) {
  final defaultPlayerIds = {
    'player-001',
    'player-003',
    'player-004',
    'player-005',
    'player-006',
    'player-007',
  };

  final defaultRotation = <int, String>{
    1: 'player-001', // Setter - Position 1
    2: 'player-003', // Outside Hitter - Position 2
    3: 'player-005', // Middle Blocker - Position 3
    4: 'player-007', // Opposite - Position 4
    5: 'player-004', // Outside Hitter - Position 5
    6: 'player-006', // Middle Blocker - Position 6
  };

  return MatchDraft(
    opponent: opponent ?? 'Eagles Volleyball Club',
    matchDate: matchDate ?? DateTime(2026, 1, 15, 18, 30),
    location: location ?? 'Main Gymnasium',
    seasonLabel: seasonLabel ?? 'Spring 2026',
    selectedPlayerIds: selectedPlayerIds ?? defaultPlayerIds,
    startingRotation: startingRotation ?? defaultRotation,
  );
}

/// Creates an empty/initial MatchDraft for testing
MatchDraft createEmptyMatchDraft() {
  return MatchDraft.initial();
}

/// Creates a partially filled MatchDraft (metadata only, no roster)
MatchDraft createPartialMatchDraft() {
  return const MatchDraft(
    opponent: 'Hawks Academy',
    matchDate: null,
    location: 'Away Court',
    seasonLabel: 'Spring 2026',
    selectedPlayerIds: <String>{},
    startingRotation: <int, String>{},
  );
}

/// Creates multiple mock teams for list testing
List<Team> createMockTeamList() {
  return [
    const Team(
      id: 'team-001',
      name: 'Thunderbolts Varsity',
      level: 'Varsity',
      seasonLabel: 'Spring 2026',
      coachId: 'coach-001',
    ),
    const Team(
      id: 'team-002',
      name: 'Thunderbolts JV',
      level: 'Junior Varsity',
      seasonLabel: 'Spring 2026',
      coachId: 'coach-001',
    ),
    const Team(
      id: 'team-003',
      name: 'Lightning U16',
      level: 'Club',
      seasonLabel: 'Spring 2026',
      coachId: 'coach-002',
    ),
  ];
}

/// Volleyball position constants for reference
class VolleyballPositions {
  static const String setter = 'Setter';
  static const String outsideHitter = 'Outside Hitter';
  static const String middleBlocker = 'Middle Blocker';
  static const String oppositeHitter = 'Opposite Hitter';
  static const String libero = 'Libero';
  static const String defensiveSpecialist = 'Defensive Specialist';

  static const List<String> all = [
    setter,
    outsideHitter,
    middleBlocker,
    oppositeHitter,
    libero,
    defensiveSpecialist,
  ];
}
