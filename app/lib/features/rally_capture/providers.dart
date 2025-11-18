import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../match_setup/constants.dart';
import '../match_setup/models/match_draft.dart';
import '../match_setup/models/match_player.dart';
import '../match_setup/providers.dart';
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
    int? currentRallyNumber,
    List<RallyEvent>? currentEvents,
    List<RallyRecord>? completedRallies,
  }) {
    state = state.copyWith(
      currentRallyNumber: currentRallyNumber,
      currentEvents: currentEvents,
      completedRallies: completedRallies,
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
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
}
