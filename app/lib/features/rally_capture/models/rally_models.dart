import '../../match_setup/models/match_player.dart';

enum RallyActionTypes {
  serveAce,
  serveError,
  firstBallKill,
  attackKill,
  attackError,
  block,
  dig,
  assist,
  timeout,
  substitution,
}

extension RallyActionTypesX on RallyActionTypes {
  String get label {
    switch (this) {
      case RallyActionTypes.serveAce:
        return 'Serve Ace';
      case RallyActionTypes.serveError:
        return 'Serve Error';
      case RallyActionTypes.firstBallKill:
        return 'First Ball Kill';
      case RallyActionTypes.attackKill:
        return 'Attack Kill';
      case RallyActionTypes.attackError:
        return 'Attack Error';
      case RallyActionTypes.block:
        return 'Block';
      case RallyActionTypes.dig:
        return 'Dig';
      case RallyActionTypes.assist:
        return 'Assist';
      case RallyActionTypes.timeout:
        return 'Timeout';
      case RallyActionTypes.substitution:
        return 'Substitution';
    }
  }

  bool get isPlayerAction {
    switch (this) {
      case RallyActionTypes.serveAce:
      case RallyActionTypes.serveError:
      case RallyActionTypes.firstBallKill:
      case RallyActionTypes.attackKill:
      case RallyActionTypes.attackError:
      case RallyActionTypes.block:
      case RallyActionTypes.dig:
      case RallyActionTypes.assist:
        return true;
      case RallyActionTypes.timeout:
      case RallyActionTypes.substitution:
        return false;
    }
  }

  bool get isPointScoring {
    switch (this) {
      case RallyActionTypes.serveAce:
      case RallyActionTypes.firstBallKill:
      case RallyActionTypes.attackKill:
      case RallyActionTypes.block:
        return true;
      case RallyActionTypes.serveError:
      case RallyActionTypes.attackError:
      case RallyActionTypes.dig:
      case RallyActionTypes.assist:
      case RallyActionTypes.timeout:
      case RallyActionTypes.substitution:
        return false;
    }
  }

  bool get isError {
    switch (this) {
      case RallyActionTypes.serveError:
      case RallyActionTypes.attackError:
        return true;
      case RallyActionTypes.serveAce:
      case RallyActionTypes.firstBallKill:
      case RallyActionTypes.attackKill:
      case RallyActionTypes.block:
      case RallyActionTypes.dig:
      case RallyActionTypes.assist:
      case RallyActionTypes.timeout:
      case RallyActionTypes.substitution:
        return false;
    }
  }
}

class RallyEvent {
  RallyEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.player,
    this.note,
  });

  final String id;
  final RallyActionTypes type;
  final DateTime timestamp;
  final MatchPlayer? player;
  final String? note;

  String get summary {
    final parts = <String>[type.label];
    if (player != null) {
      parts.add('#${player!.jerseyNumber} ${player!.name}');
    }
    if (note != null && note!.isNotEmpty) {
      parts.add(note!);
    }
    return parts.join(' • ');
  }

  RallyEvent copyWith({
    String? id,
    RallyActionTypes? type,
    DateTime? timestamp,
    MatchPlayer? player,
    String? note,
  }) {
    return RallyEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      player: player ?? this.player,
      note: note ?? this.note,
    );
  }
}

class RallyRecord {
  RallyRecord({
    required this.rallyId,
    required this.rallyNumber,
    required List<RallyEvent> events,
    required this.completedAt,
  }) : events = List<RallyEvent>.unmodifiable(events);

  final String rallyId;
  final int rallyNumber;
  final List<RallyEvent> events;
  final DateTime completedAt;

  RallyRecord copyWith({
    String? rallyId,
    int? rallyNumber,
    List<RallyEvent>? events,
    DateTime? completedAt,
  }) {
    return RallyRecord(
      rallyId: rallyId ?? this.rallyId,
      rallyNumber: rallyNumber ?? this.rallyNumber,
      events: events ?? this.events,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class RallyCaptureSession {
  RallyCaptureSession({
    required this.matchId,
    required this.setId,
    required this.currentRallyNumber,
    required List<RallyEvent> currentEvents,
    required List<RallyRecord> completedRallies,
    required this.canUndo,
    required this.canRedo,
  })  : currentEvents = List<RallyEvent>.unmodifiable(currentEvents),
        completedRallies = List<RallyRecord>.unmodifiable(completedRallies);

  final String matchId;
  final String setId;
  final int currentRallyNumber;
  final List<RallyEvent> currentEvents;
  final List<RallyRecord> completedRallies;
  final bool canUndo;
  final bool canRedo;

  factory RallyCaptureSession.initial({
    required String matchId,
    required String setId,
  }) {
    return RallyCaptureSession(
      matchId: matchId,
      setId: setId,
      currentRallyNumber: 1,
      currentEvents: const [],
      completedRallies: const [],
      canUndo: false,
      canRedo: false,
    );
  }

  bool get hasCompletedRallies => completedRallies.isNotEmpty;
  bool get hasCurrentEvents => currentEvents.isNotEmpty;
  
  bool get canCompleteRally {
    return currentEvents.isNotEmpty && 
           currentEvents.any((event) => 
               event.type.isPointScoring || event.type.isError);
  }

  RallyCaptureSession copyWith({
    String? matchId,
    String? setId,
    int? currentRallyNumber,
    List<RallyEvent>? currentEvents,
    List<RallyRecord>? completedRallies,
    bool? canUndo,
    bool? canRedo,
  }) {
    return RallyCaptureSession(
      matchId: matchId ?? this.matchId,
      setId: setId ?? this.setId,
      currentRallyNumber: currentRallyNumber ?? this.currentRallyNumber,
      currentEvents: currentEvents ?? this.currentEvents,
      completedRallies: completedRallies ?? this.completedRallies,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}
