import 'package:hive/hive.dart';
import '../../features/match_setup/models/match_draft.dart';
import '../../features/match_setup/models/match_player.dart';
import '../../features/match_setup/models/roster_template.dart';
import '../../features/rally_capture/models/rally_models.dart';

/// Type adapter for MatchDraft (TypeId: 0)
class MatchDraftAdapter extends TypeAdapter<Map> {
  @override
  final int typeId = 0;

  @override
  Map read(BinaryReader reader) {
    return reader.readMap().cast<String, dynamic>();
  }

  @override
  void write(BinaryWriter writer, Map obj) {
    writer.writeMap(obj);
  }
}

/// Type adapter for MatchPlayer (TypeId: 1)
class MatchPlayerAdapter extends TypeAdapter<Map> {
  @override
  final int typeId = 1;

  @override
  Map read(BinaryReader reader) {
    return reader.readMap().cast<String, dynamic>();
  }

  @override
  void write(BinaryWriter writer, Map obj) {
    writer.writeMap(obj);
  }
}

/// Type adapter for RosterTemplate (TypeId: 2)
class RosterTemplateAdapter extends TypeAdapter<Map> {
  @override
  final int typeId = 2;

  @override
  Map read(BinaryReader reader) {
    return reader.readMap().cast<String, dynamic>();
  }

  @override
  void write(BinaryWriter writer, Map obj) {
    writer.writeMap(obj);
  }
}

/// Type adapter for RallyEvent (TypeId: 3)
class RallyEventAdapter extends TypeAdapter<Map> {
  @override
  final int typeId = 3;

  @override
  Map read(BinaryReader reader) {
    return reader.readMap().cast<String, dynamic>();
  }

  @override
  void write(BinaryWriter writer, Map obj) {
    writer.writeMap(obj);
  }
}

/// Type adapter for RallyRecord (TypeId: 4)
class RallyRecordAdapter extends TypeAdapter<Map> {
  @override
  final int typeId = 4;

  @override
  Map read(BinaryReader reader) {
    return reader.readMap().cast<String, dynamic>();
  }

  @override
  void write(BinaryWriter writer, Map obj) {
    writer.writeMap(obj);
  }
}

/// Type adapter for RallyCaptureSession (TypeId: 5)
class RallyCaptureSessionAdapter extends TypeAdapter<Map> {
  @override
  final int typeId = 5;

  @override
  Map read(BinaryReader reader) {
    return reader.readMap().cast<String, dynamic>();
  }

  @override
  void write(BinaryWriter writer, Map obj) {
    writer.writeMap(obj);
  }
}

/// Type adapter for sync queue items (TypeId: 6)
class SyncQueueItemAdapter extends TypeAdapter<Map> {
  @override
  final int typeId = 6;

  @override
  Map read(BinaryReader reader) {
    return reader.readMap().cast<String, dynamic>();
  }

  @override
  void write(BinaryWriter writer, Map obj) {
    writer.writeMap(obj);
  }
}

/// Helper class to serialize/deserialize domain models to/from Hive-compatible Maps
class ModelSerializer {
  /// Serialize MatchDraft to Map
  static Map<String, dynamic> matchDraftToMap(MatchDraft draft) {
    return draft.toMap();
  }

  /// Deserialize MatchDraft from Map
  static MatchDraft matchDraftFromMap(Map<String, dynamic> map) {
    return MatchDraft.fromMap(map);
  }

  /// Serialize MatchPlayer to Map
  static Map<String, dynamic> matchPlayerToMap(MatchPlayer player) {
    final nameParts = player.name.split(' ');
    return {
      'id': player.id,
      'first_name': nameParts.isNotEmpty ? nameParts.first : '',
      'last_name': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      'jersey_number': player.jerseyNumber,
      'position': player.position,
    };
  }

  /// Deserialize MatchPlayer from Map
  static MatchPlayer matchPlayerFromMap(Map<String, dynamic> map) {
    return MatchPlayer(
      id: map['id'] as String,
      name: '${map['first_name'] ?? ''} ${map['last_name'] ?? ''}'.trim(),
      jerseyNumber: (map['jersey_number'] as num?)?.toInt() ?? 0,
      position: (map['position'] as String?) ?? '',
    );
  }

  /// Serialize RosterTemplate to Map
  static Map<String, dynamic> rosterTemplateToMap(RosterTemplate template) {
    return template.toMap();
  }

  /// Deserialize RosterTemplate from Map
  static RosterTemplate rosterTemplateFromMap(Map<String, dynamic> map) {
    return RosterTemplate.fromMap(map);
  }

  /// Serialize RallyEvent to Map
  static Map<String, dynamic> rallyEventToMap(RallyEvent event) {
    return {
      'id': event.id,
      'type': event.type.name,
      'timestamp': event.timestamp.toIso8601String(),
      if (event.player != null) 'player': matchPlayerToMap(event.player!),
      if (event.note != null) 'note': event.note,
    };
  }

  /// Deserialize RallyEvent from Map
  static RallyEvent rallyEventFromMap(Map<String, dynamic> map) {
    return RallyEvent(
      id: map['id'] as String,
      type: RallyActionTypes.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RallyActionTypes.attackAttempt,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      player: map['player'] != null
          ? matchPlayerFromMap(map['player'] as Map<String, dynamic>)
          : null,
      note: map['note'] as String?,
    );
  }

  /// Serialize RallyRecord to Map
  static Map<String, dynamic> rallyRecordToMap(RallyRecord record) {
    return {
      'rallyId': record.rallyId,
      'rallyNumber': record.rallyNumber,
      'rotationNumber': record.rotationNumber,
      'events': record.events.map(rallyEventToMap).toList(),
      'completedAt': record.completedAt.toIso8601String(),
    };
  }

  /// Deserialize RallyRecord from Map
  static RallyRecord rallyRecordFromMap(Map<String, dynamic> map) {
    final eventsData = map['events'] as List? ?? [];
    final events = eventsData
        .map((e) => rallyEventFromMap(e as Map<String, dynamic>))
        .toList();

    return RallyRecord(
      rallyId: map['rallyId'] as String,
      rallyNumber: (map['rallyNumber'] as num?)?.toInt() ?? 0,
      rotationNumber: (map['rotationNumber'] as num?)?.toInt() ?? 1,
      events: events,
      completedAt: DateTime.parse(map['completedAt'] as String),
    );
  }

  /// Serialize RallyCaptureSession to Map
  static Map<String, dynamic> rallyCaptureSessionToMap(
      RallyCaptureSession session) {
    return {
      'matchId': session.matchId,
      'setId': session.setId,
      'currentSetNumber': session.currentSetNumber,
      'currentRallyNumber': session.currentRallyNumber,
      'currentRotation': session.currentRotation,
      'currentEvents': session.currentEvents.map(rallyEventToMap).toList(),
      'completedRallies':
          session.completedRallies.map(rallyRecordToMap).toList(),
      'canUndo': session.canUndo,
      'canRedo': session.canRedo,
    };
  }

  /// Deserialize RallyCaptureSession from Map
  static RallyCaptureSession rallyCaptureSessionFromMap(
      Map<String, dynamic> map) {
    final currentEventsData = map['currentEvents'] as List? ?? [];
    final currentEvents = currentEventsData
        .map((e) => rallyEventFromMap(e as Map<String, dynamic>))
        .toList();

    final completedRalliesData = map['completedRallies'] as List? ?? [];
    final completedRallies = completedRalliesData
        .map((e) => rallyRecordFromMap(e as Map<String, dynamic>))
        .toList();

    return RallyCaptureSession(
      matchId: map['matchId'] as String,
      setId: map['setId'] as String,
      currentSetNumber: (map['currentSetNumber'] as num?)?.toInt() ?? 1,
      currentRallyNumber: (map['currentRallyNumber'] as num?)?.toInt() ?? 1,
      currentRotation: (map['currentRotation'] as num?)?.toInt() ?? 1,
      currentEvents: currentEvents,
      completedRallies: completedRallies,
      canUndo: map['canUndo'] as bool? ?? false,
      canRedo: map['canRedo'] as bool? ?? false,
    );
  }
}
