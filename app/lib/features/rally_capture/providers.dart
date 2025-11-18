import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../match_setup/constants.dart';
import '../match_setup/models/match_draft.dart';
import '../match_setup/models/match_player.dart';
import '../match_setup/providers.dart';
import '../teams/team_providers.dart';
import 'models/rally_models.dart';
import 'data/rally_sync_repository.dart';

class RallyCaptureState {
  RallyCaptureState({
    required this.draft,
    required this.activePlayers,
    required this.benchPlayers,
    required this.rotation,
    required this.currentRotation,
  });

  final MatchDraft draft;
  final List<MatchPlayer> activePlayers;
  final List<MatchPlayer> benchPlayers;
  final Map<int, MatchPlayer?> rotation;
  final int currentRotation; // Current rotation position (1-6)
}

/// Current lineup state that can be updated during the match (e.g., substitutions)
class CurrentLineup {
  CurrentLineup({
    required this.activePlayers,
    required this.benchPlayers,
  });

  final List<MatchPlayer> activePlayers;
  final List<MatchPlayer> benchPlayers;

  CurrentLineup copyWith({
    List<MatchPlayer>? activePlayers,
    List<MatchPlayer>? benchPlayers,
  }) {
    return CurrentLineup(
      activePlayers: activePlayers ?? this.activePlayers,
      benchPlayers: benchPlayers ?? this.benchPlayers,
    );
  }
}

/// Provider that manages the current lineup and can be updated during the match
final currentLineupProvider = StateNotifierProvider.family<CurrentLineupNotifier, CurrentLineup, String>((ref, matchId) {
  final stateAsync = ref.watch(rallyCaptureStateProvider(matchId));
  
  if (!stateAsync.hasValue) {
    return CurrentLineupNotifier(CurrentLineup(activePlayers: const [], benchPlayers: const []));
  }
  
  final state = stateAsync.value!;
  return CurrentLineupNotifier(
    CurrentLineup(
      activePlayers: List<MatchPlayer>.from(state.activePlayers),
      benchPlayers: List<MatchPlayer>.from(state.benchPlayers),
    ),
  );
});

class CurrentLineupNotifier extends StateNotifier<CurrentLineup> {
  CurrentLineupNotifier(CurrentLineup initial) : super(initial);

  /// Perform a substitution: swap outgoing player with incoming player
  void substitute(MatchPlayer outgoing, MatchPlayer incoming) {
    final newActive = List<MatchPlayer>.from(state.activePlayers);
    final newBench = List<MatchPlayer>.from(state.benchPlayers);
    
    // Remove outgoing from active, add to bench
    newActive.removeWhere((p) => p.id == outgoing.id);
    if (!newBench.any((p) => p.id == outgoing.id)) {
      newBench.add(outgoing);
    }
    
    // Remove incoming from bench, add to active
    newBench.removeWhere((p) => p.id == incoming.id);
    if (!newActive.any((p) => p.id == incoming.id)) {
      newActive.add(incoming);
    }
    
    state = CurrentLineup(
      activePlayers: newActive,
      benchPlayers: newBench,
    );
  }
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
  
  // Use selected team ID, fallback to defaultTeamId for backwards compatibility
  final selectedTeamId = ref.watch(selectedTeamIdProvider);
  final effectiveTeamId = selectedTeamId ?? defaultTeamId;
  
  final roster = await repository.fetchRoster(teamId: effectiveTeamId);
  
  // Filter players based on draft selection
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
    currentRotation: 1, // Start with rotation 1
  );
});

// Mock repository used when Supabase is not available
class MockRallySyncRepository implements RallySyncRepository {
  @override
  Future<void> init() async {}
  
  @override
  Future<void> queueRallyForSync({
    required String matchId,
    required String setId,
    required RallyRecord rallyRecord,
    required int rotation,
  }) async {}
  
  @override
  Future<void> queueSpecialActionForSync({
    required String setId,
    required String? rallyId,
    required RallyActionTypes actionType,
    required MatchPlayer? playerIn,
    required MatchPlayer? playerOut,
    required String? note,
  }) async {}
  
  @override
  Future<SyncResult> syncPendingRallies() async {
    return SyncResult(success: true, synced: 0, failed: 0);
  }
  
  @override
  SyncStatus getSyncStatus() {
    return const SyncStatus();
  }
  
  @override
  int get pendingRalliesCount => 0;
  
  @override
  Future<void> clearPendingRallies() async {}
}

// Provider for the rally sync repository
final rallySyncRepositoryProvider = Provider<RallySyncRepository>((ref) {
  return MockRallySyncRepository();
});



final rallyCaptureSessionProvider = StateNotifierProvider.family<
    RallyCaptureSessionController, RallyCaptureSession, String>(
  (ref, matchId) {
    // For now, we'll use a hardcoded set ID. In a real implementation,
    // this would come from the match setup flow
    const setId = 'default-set-id';
    return RallyCaptureSessionController(
      matchId: matchId,
      setId: setId,
      syncRepository: ref.watch(rallySyncRepositoryProvider),
    );
  },
);

abstract class _HistoryEntry {
  const _HistoryEntry();
}

class _ActionHistoryEntry extends _HistoryEntry {
  const _ActionHistoryEntry(this.event);

  final RallyEvent event;
}

class _RallyHistoryEntry extends _HistoryEntry {
  const _RallyHistoryEntry(this.record);

  final RallyRecord record;
}

class RallyCaptureSessionController extends StateNotifier<RallyCaptureSession> {
  RallyCaptureSessionController({
    required String matchId,
    required String setId,
    required RallySyncRepository syncRepository,
  })  : _syncRepository = syncRepository,
        super(RallyCaptureSession.initial(matchId: matchId, setId: setId));

  final RallySyncRepository _syncRepository;
  final _uuid = const Uuid();
  final List<_HistoryEntry> _undoStack = <_HistoryEntry>[];
  final List<_HistoryEntry> _redoStack = <_HistoryEntry>[];

  void logAction(
    RallyActionTypes type, {
    MatchPlayer? player,
    String? note,
  }) async {
    final event = RallyEvent(
      id: _uuid.v4(),
      type: type,
      timestamp: DateTime.now(),
      player: player,
      note: note,
    );
    final updatedEvents = List<RallyEvent>.from(state.currentEvents)
      ..add(event);
    _undoStack.add(_ActionHistoryEntry(event));
    _redoStack.clear();
    _updateState(currentEvents: updatedEvents);

    // For special actions (timeout, substitution), save immediately
    if (!type.isPlayerAction) {
      await _syncRepository.queueSpecialActionForSync(
        setId: state.setId,
        rallyId: null, // Not tied to a specific rally yet
        actionType: type,
        playerIn: note?.contains('In:') == true 
            ? _extractPlayerFromNote(note!, 'In:')
            : null,
        playerOut: note?.contains('Out:') == true 
            ? _extractPlayerFromNote(note!, 'Out:')
            : null,
        note: note,
      );
    }
  }

  Future<bool> completeRally() async {
    if (!state.canCompleteRally) {
      return false;
    }

    final record = RallyRecord(
      rallyId: _uuid.v4(),
      rallyNumber: state.currentRallyNumber,
      events: List<RallyEvent>.from(state.currentEvents),
      completedAt: DateTime.now(),
    );
    final completed = List<RallyRecord>.from(state.completedRallies)
      ..add(record);
    _undoStack.add(_RallyHistoryEntry(record));
    _redoStack.clear();

    try {
      // Queue for sync (will try immediate sync if online)
      await _syncRepository.queueRallyForSync(
        matchId: state.matchId,
        setId: state.setId,
        rallyRecord: record,
        rotation: 1, // TODO: Get current rotation from UI state
      );
    } catch (e) {
      // Log error but don't fail the operation - rally stays in local state
      print('Failed to sync rally: $e');
    }

    _updateState(
      currentRallyNumber: state.currentRallyNumber + 1,
      currentEvents: const <RallyEvent>[],
      completedRallies: completed,
    );
    return true;
  }

  bool undo() {
    if (_undoStack.isEmpty) {
      return false;
    }
    final entry = _undoStack.removeLast();
    if (entry is _ActionHistoryEntry) {
      final events = List<RallyEvent>.from(state.currentEvents);
      final index =
          events.lastIndexWhere((event) => event.id == entry.event.id);
      if (index >= 0) {
        events.removeAt(index);
      } else {
        for (var i = state.completedRallies.length - 1; i >= 0; i--) {
          final record = state.completedRallies[i];
          final recordIndex = record.events
              .lastIndexWhere((event) => event.id == entry.event.id);
          if (recordIndex >= 0) {
            final updatedRecordEvents = List<RallyEvent>.from(record.events)
              ..removeAt(recordIndex);
            final updatedCompleted =
                List<RallyRecord>.from(state.completedRallies);
            updatedCompleted[i] = record.copyWith(
              events: updatedRecordEvents,
            );
            _redoStack.add(entry);
            _updateState(completedRallies: updatedCompleted);
            return true;
          }
        }
      }
      _redoStack.add(entry);
      _updateState(currentEvents: events);
      return true;
    }

    if (entry is _RallyHistoryEntry) {
      final updatedCompleted = List<RallyRecord>.from(state.completedRallies);
      final index = updatedCompleted.lastIndexWhere(
        (record) => record.rallyNumber == entry.record.rallyNumber,
      );
      if (index >= 0) {
        updatedCompleted.removeAt(index);
      }
      _redoStack.add(entry);
      _updateState(
        currentRallyNumber: entry.record.rallyNumber,
        currentEvents: List<RallyEvent>.from(entry.record.events),
        completedRallies: updatedCompleted,
      );
      return true;
    }

    return false;
  }

  bool redo() {
    if (_redoStack.isEmpty) {
      return false;
    }
    final entry = _redoStack.removeLast();
    if (entry is _ActionHistoryEntry) {
      final events = List<RallyEvent>.from(state.currentEvents)
        ..add(entry.event);
      _undoStack.add(entry);
      _updateState(currentEvents: events);
      return true;
    }
    if (entry is _RallyHistoryEntry) {
      final completed = List<RallyRecord>.from(state.completedRallies)
        ..add(entry.record);
      _undoStack.add(entry);
      _updateState(
        currentRallyNumber: entry.record.rallyNumber + 1,
        currentEvents: const <RallyEvent>[],
        completedRallies: completed,
      );
      return true;
    }
    return false;
  }

  void _updateState({
    String? setId,
    int? currentSetNumber,
    int? currentRallyNumber,
    List<RallyEvent>? currentEvents,
    List<RallyRecord>? completedRallies,
    bool? canUndo,
    bool? canRedo,
  }) {
    state = state.copyWith(
      setId: setId,
      currentSetNumber: currentSetNumber,
      currentRallyNumber: currentRallyNumber,
      currentEvents: currentEvents,
      completedRallies: completedRallies,
      canUndo: canUndo ?? _undoStack.isNotEmpty,
      canRedo: canRedo ?? _redoStack.isNotEmpty,
    );
  }

  /// Start a new set (increment set number, reset rally counter and events)
  Future<void> startNewSet() async {
    final newSetNumber = state.currentSetNumber + 1;
    final newSetId = '${state.matchId}-set-$newSetNumber';
    
    // Clear undo/redo stacks for new set
    _undoStack.clear();
    _redoStack.clear();
    
    _updateState(
      setId: newSetId,
      currentSetNumber: newSetNumber,
      currentRallyNumber: 1,
      currentEvents: const [],
      completedRallies: const [],
      canUndo: false,
      canRedo: false,
    );
  }

  MatchPlayer? _extractPlayerFromNote(String note, String prefix) {
    // Simple extraction logic - in a real app, this would be more robust
    // Format expected: "Out: #5 Smith" or "In: #12 Jones"
    final parts = note.split(prefix);
    if (parts.length < 2) return null;
    
    final playerPart = parts[1].trim();
    final jerseyMatch = RegExp(r'#(\d+)').firstMatch(playerPart);
    if (jerseyMatch == null) return null;
    
    final jerseyNumber = int.tryParse(jerseyMatch.group(1)!);
    if (jerseyNumber == null) return null;
    
    // This is a simplified approach - in reality, you'd match against
    // the actual roster to find the player by jersey number
    return null; // Return null for now since we don't have roster access
  }

  // Quick action: Complete rally with win
  Future<bool> completeRallyWithWin({MatchPlayer? player, RallyActionTypes? actionType}) async {
    // If we have events, just complete. Otherwise, add a win action first.
    if (state.currentEvents.isEmpty) {
      if (player != null && actionType != null) {
        logAction(actionType, player: player);
      } else {
        // Default to a generic attack kill for win (no player specified)
        logAction(RallyActionTypes.attackKill);
      }
    }
    return await completeRally();
  }

  // Quick action: Complete rally with loss
  Future<bool> completeRallyWithLoss({MatchPlayer? player, RallyActionTypes? actionType}) async {
    // Always ensure we have a loss-indicating event
    // If no events exist, add an attack error
    // If events exist but none are errors, add an attack error to ensure loss
    bool hasError = state.currentEvents.any((e) => e.type.isError);
    
    if (state.currentEvents.isEmpty || !hasError) {
      if (player != null && actionType != null && actionType.isError) {
        logAction(actionType, player: player);
      } else {
        // Default to a generic attack error for loss
        logAction(RallyActionTypes.attackError);
      }
    }
    return await completeRally();
  }
}

/// Running totals calculated from completed rallies
class RunningTotals {
  RunningTotals({
    required this.fbk,
    required this.wins,
    required this.losses,
    required this.transitionPoints,
    required this.serveAces,
    required this.serveErrors,
    required this.attackKills,
    required this.attackErrors,
    required this.blocks,
    required this.digs,
    required this.assists,
    required this.substitutions,
    required this.timeouts,
  });

  final int fbk;
  final int wins;
  final int losses;
  final int transitionPoints;
  final int serveAces;
  final int serveErrors;
  final int attackKills;
  final int attackErrors;
  final int blocks;
  final int digs;
  final int assists;
  final int substitutions;
  final int timeouts;

  int get totalRallies => wins + losses;
  double get winPercentage => totalRallies > 0 ? (wins / totalRallies * 100) : 0.0;
  
  // Volleyball allows 15 substitutions per set
  static const int maxSubstitutionsPerSet = 15;
  int get substitutionsRemaining => maxSubstitutionsPerSet - substitutions;
  bool get canSubstitute => substitutionsRemaining > 0;
}

/// Provider that calculates running totals from rally session
final runningTotalsProvider = Provider.family<RunningTotals, String>((ref, matchId) {
  final session = ref.watch(rallyCaptureSessionProvider(matchId));
  
  int fbk = 0;
  int wins = 0;
  int losses = 0;
  int transitionPoints = 0;
  int serveAces = 0;
  int serveErrors = 0;
  int attackKills = 0;
  int attackErrors = 0;
  int blocks = 0;
  int digs = 0;
  int assists = 0;
  int substitutions = 0;
  int timeouts = 0;

  // Count substitutions and timeouts from both completed rallies AND current events
  // (they should update immediately when logged, not wait for rally completion)
  final allTimeoutSubEvents = <RallyEvent>[];
  
  // Add from completed rallies
  for (final rally in session.completedRallies) {
    allTimeoutSubEvents.addAll(rally.events);
  }
  
  // Add from current events (for immediate counter updates)
  allTimeoutSubEvents.addAll(session.currentEvents);
  
  for (final event in allTimeoutSubEvents) {
    if (event.type == RallyActionTypes.substitution) {
      substitutions++;
    } else if (event.type == RallyActionTypes.timeout) {
      timeouts++;
    }
  }

  // Count other stats from completed rallies only
  for (final rally in session.completedRallies) {
    bool isWin = false;
    bool isLoss = false;
    bool hasFBK = false;
    bool isTransition = false;

    for (final event in rally.events) {
      // Count action types
      switch (event.type) {
        case RallyActionTypes.firstBallKill:
          fbk++;
          hasFBK = true;
          isTransition = true;
          break;
        case RallyActionTypes.serveAce:
          serveAces++;
          isWin = true;
          break;
        case RallyActionTypes.serveError:
          serveErrors++;
          isLoss = true;
          break;
        case RallyActionTypes.attackKill:
          attackKills++;
          isWin = true;
          break;
        case RallyActionTypes.attackError:
          attackErrors++;
          isLoss = true;
          break;
        case RallyActionTypes.block:
          blocks++;
          isWin = true;
          break;
        case RallyActionTypes.dig:
          digs++;
          break;
        case RallyActionTypes.assist:
          assists++;
          break;
        default:
          break;
      }
    }

    // Determine win/loss based on point-scoring actions or errors
    if (!isWin && !isLoss) {
      // Check if rally ended with a point-scoring action (win) or error (loss)
      final lastEvent = rally.events.isNotEmpty ? rally.events.last : null;
      if (lastEvent != null) {
        if (lastEvent.type.isPointScoring) {
          isWin = true;
        } else if (lastEvent.type.isError) {
          isLoss = true;
        }
      }
    }

    if (isWin) {
      wins++;
      if (hasFBK || isTransition) {
        transitionPoints++;
      }
    } else if (isLoss) {
      losses++;
    }
  }

  // Note: We don't count current events for substitutions/timeouts here because:
  // 1. They will be counted when the rally completes
  // 2. Substitutions/timeouts can happen between rallies, so they're logged as events
  //    but we only want to count them once when the rally is finalized

  return RunningTotals(
    fbk: fbk,
    wins: wins,
    losses: losses,
    transitionPoints: transitionPoints,
    serveAces: serveAces,
    serveErrors: serveErrors,
    attackKills: attackKills,
    attackErrors: attackErrors,
    blocks: blocks,
    digs: digs,
    assists: assists,
    substitutions: substitutions,
    timeouts: timeouts,
  );
});

/// Player statistics breakdown
class PlayerStats {
  PlayerStats({
    required this.player,
    required this.attackKills,
    required this.attackErrors,
    required this.attackAttempts,
    required this.blocks,
    required this.digs,
    required this.assists,
    required this.serveAces,
    required this.serveErrors,
    required this.fbk,
  });

  final MatchPlayer player;
  final int attackKills;
  final int attackErrors;
  final int attackAttempts;
  final int blocks;
  final int digs;
  final int assists;
  final int serveAces;
  final int serveErrors;
  final int fbk;

  int get totalAttacks => attackKills + attackErrors + attackAttempts;
  double get attackPercentage => totalAttacks > 0 ? (attackKills / totalAttacks * 100) : 0.0;
  // Attack Efficiency = (Kills - Errors) / Total Attempts
  double get attackEfficiency => totalAttacks > 0 ? ((attackKills - attackErrors) / totalAttacks) : 0.0;
  int get totalServes => serveAces + serveErrors;
  double get servePercentage => totalServes > 0 ? (serveAces / totalServes * 100) : 0.0;
}

/// Provider that calculates per-player statistics
final playerStatsProvider = Provider.family<List<PlayerStats>, String>((ref, matchId) {
  final session = ref.watch(rallyCaptureSessionProvider(matchId));
  final stateAsync = ref.watch(rallyCaptureStateProvider(matchId));
  
  // Return empty list if state is not loaded
  if (!stateAsync.hasValue) {
    return [];
  }
  
  final state = stateAsync.value!;
  final Map<String, PlayerStats> statsMap = {};
  
  // Initialize stats for ALL players on the team roster (active + bench)
  // This ensures any player can be substituted in and will have stats initialized
  final allRosterPlayers = <MatchPlayer>[];
  allRosterPlayers.addAll(state.activePlayers);
  allRosterPlayers.addAll(state.benchPlayers);
  
  // Initialize stats for all roster players
  for (final player in allRosterPlayers) {
    statsMap[player.id] = PlayerStats(
      player: player,
      attackKills: 0,
      attackErrors: 0,
      attackAttempts: 0,
      blocks: 0,
      digs: 0,
      assists: 0,
      serveAces: 0,
      serveErrors: 0,
      fbk: 0,
    );
  }

  // Count stats from completed rallies AND current events (for live updates)
  final allEvents = <RallyEvent>[];
  
  // Add completed rally events
  for (final rally in session.completedRallies) {
    allEvents.addAll(rally.events);
  }
  
  // Add current rally events (for live stat updates)
  allEvents.addAll(session.currentEvents);
  
  for (final event in allEvents) {
    if (event.player == null) continue;
    
    final playerId = event.player!.id;
    if (!statsMap.containsKey(playerId)) continue;
    
    final current = statsMap[playerId]!;
    
    switch (event.type) {
        case RallyActionTypes.attackKill:
          statsMap[playerId] = PlayerStats(
            player: current.player,
            attackKills: current.attackKills + 1,
            attackErrors: current.attackErrors,
            attackAttempts: current.attackAttempts,
            blocks: current.blocks,
            digs: current.digs,
            assists: current.assists,
            serveAces: current.serveAces,
            serveErrors: current.serveErrors,
            fbk: current.fbk,
          );
          break;
        case RallyActionTypes.attackError:
          statsMap[playerId] = PlayerStats(
            player: current.player,
            attackKills: current.attackKills,
            attackErrors: current.attackErrors + 1,
            attackAttempts: current.attackAttempts,
            blocks: current.blocks,
            digs: current.digs,
            assists: current.assists,
            serveAces: current.serveAces,
            serveErrors: current.serveErrors,
            fbk: current.fbk,
          );
          break;
        case RallyActionTypes.attackAttempt:
          statsMap[playerId] = PlayerStats(
            player: current.player,
            attackKills: current.attackKills,
            attackErrors: current.attackErrors,
            attackAttempts: current.attackAttempts + 1,
            blocks: current.blocks,
            digs: current.digs,
            assists: current.assists,
            serveAces: current.serveAces,
            serveErrors: current.serveErrors,
            fbk: current.fbk,
          );
          break;
        case RallyActionTypes.block:
          statsMap[playerId] = PlayerStats(
            player: current.player,
            attackKills: current.attackKills,
            attackErrors: current.attackErrors,
            attackAttempts: current.attackAttempts,
            blocks: current.blocks + 1,
            digs: current.digs,
            assists: current.assists,
            serveAces: current.serveAces,
            serveErrors: current.serveErrors,
            fbk: current.fbk,
          );
          break;
        case RallyActionTypes.dig:
          statsMap[playerId] = PlayerStats(
            player: current.player,
            attackKills: current.attackKills,
            attackErrors: current.attackErrors,
            attackAttempts: current.attackAttempts,
            blocks: current.blocks,
            digs: current.digs + 1,
            assists: current.assists,
            serveAces: current.serveAces,
            serveErrors: current.serveErrors,
            fbk: current.fbk,
          );
          break;
        case RallyActionTypes.assist:
          statsMap[playerId] = PlayerStats(
            player: current.player,
            attackKills: current.attackKills,
            attackErrors: current.attackErrors,
            attackAttempts: current.attackAttempts,
            blocks: current.blocks,
            digs: current.digs,
            assists: current.assists + 1,
            serveAces: current.serveAces,
            serveErrors: current.serveErrors,
            fbk: current.fbk,
          );
          break;
        case RallyActionTypes.serveAce:
          statsMap[playerId] = PlayerStats(
            player: current.player,
            attackKills: current.attackKills,
            attackErrors: current.attackErrors,
            attackAttempts: current.attackAttempts,
            blocks: current.blocks,
            digs: current.digs,
            assists: current.assists,
            serveAces: current.serveAces + 1,
            serveErrors: current.serveErrors,
            fbk: current.fbk,
          );
          break;
        case RallyActionTypes.serveError:
          statsMap[playerId] = PlayerStats(
            player: current.player,
            attackKills: current.attackKills,
            attackErrors: current.attackErrors,
            attackAttempts: current.attackAttempts,
            blocks: current.blocks,
            digs: current.digs,
            assists: current.assists,
            serveAces: current.serveAces,
            serveErrors: current.serveErrors + 1,
            fbk: current.fbk,
          );
          break;
        case RallyActionTypes.firstBallKill:
          statsMap[playerId] = PlayerStats(
            player: current.player,
            attackKills: current.attackKills,
            attackErrors: current.attackErrors,
            attackAttempts: current.attackAttempts,
            blocks: current.blocks,
            digs: current.digs,
            assists: current.assists,
            serveAces: current.serveAces,
            serveErrors: current.serveErrors,
            fbk: current.fbk + 1,
          );
          break;
        default:
          break;
      }
    }

  return statsMap.values.toList()
    ..sort((a, b) => a.player.jerseyNumber.compareTo(b.player.jerseyNumber));
});
