
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase.dart';
import '../models/rally_models.dart';
import '../../match_setup/models/match_player.dart';

/// Repository for persisting rally data to Supabase
class RallyRepository {
  const RallyRepository(this._client);

  final SupabaseClient _client;

  /// Save a completed rally and its actions to Supabase
  Future<void> saveRally({
    required String matchId,
    required String setId,
    required RallyRecord rallyRecord,
    required int rotation,
  }) async {
    try {
      // First create the rally record
      final rallyData = {
        'id': rallyRecord.rallyId,
        'set_id': setId,
        'rally_number': rallyRecord.rallyNumber,
        'rotation': rotation,
        'result': _determineRallyResult(rallyRecord.events),
        'transition_type': _determineTransitionType(rallyRecord.events),
        'created_at': rallyRecord.completedAt.toIso8601String(),
      };

      await _client.from('rallies').insert(rallyData);

      // Then save all actions for this rally
      final actionsData = rallyRecord.events.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        
        return {
          'id': event.id,
          'rally_id': rallyRecord.rallyId,
          'player_id': event.player?.id,
          'action_type': _mapActionTypeToDb(event.type),
          'action_subtype': _mapActionSubtype(event.type),
          'outcome': _determineActionOutcome(event),
          'sequence': index + 1,
          'metadata': {
            'note': event.note,
            'timestamp': event.timestamp.toIso8601String(),
          },
          'recorded_at': event.timestamp.toIso8601String(),
        };
      }).toList();

      if (actionsData.isNotEmpty) {
        await _client.from('actions').insert(actionsData);
      }
    } catch (e) {
      throw RallyRepositoryException('Failed to save rally: $e');
    }
  }

  /// Save special actions (substitutions, timeouts) that span sets
  Future<void> saveSpecialAction({
    required String setId,
    required String? rallyId,
    required RallyActionTypes actionType,
    required MatchPlayer? playerIn,
    required MatchPlayer? playerOut,
    required String? note,
  }) async {
    try {
      switch (actionType) {
        case RallyActionTypes.substitution:
          if (playerIn == null || playerOut == null) {
            throw ArgumentError('Both playerIn and playerOut required for substitution');
          }
          await _client.from('substitutions').insert({
            'id': SupabaseSingleton.instance.client?.auth.currentUser?.id,
            'set_id': setId,
            'rally_id': rallyId,
            'player_in': playerIn.id,
            'player_out': playerOut.id,
            'reason': note,
            'created_at': DateTime.now().toIso8601String(),
          });
          break;
          
        case RallyActionTypes.timeout:
          final takenBy = note?.toLowerCase().contains('opponent') == true 
              ? 'opponent' 
              : 'us';
          await _client.from('timeouts').insert({
            'id': SupabaseSingleton.instance.client?.auth.currentUser?.id,
            'set_id': setId,
            'rally_id': rallyId,
            'taken_by': takenBy,
            'reason': note,
            'created_at': DateTime.now().toIso8601String(),
          });
          break;
          
        default:
          throw ArgumentError('Unsupported special action type: $actionType');
      }
    } catch (e) {
      throw RallyRepositoryException('Failed to save special action: $e');
    }
  }

  /// Load existing rallies for a set
  Future<List<RallyRecord>> loadRallies(String setId) async {
    try {
      final response = await _client
          .from('rallies')
          .select('''
            id,
            rally_number,
            rotation,
            result,
            transition_type,
            created_at,
            actions (
              id,
              player_id,
              action_type,
              action_subtype,
              outcome,
              sequence,
              metadata,
              recorded_at
            )
          ''')
          .eq('set_id', setId)
          .order('rally_number', ascending: true)
          .order('actions', ascending: true, referencedTable: 'actions');

      final List<RallyRecord> rallies = [];
      
      for (final rallyData in response) {
        final events = <RallyEvent>[];
        
        if (rallyData['actions'] != null) {
          for (final actionData in rallyData['actions']) {
            final metadata = actionData['metadata'] as Map<String, dynamic>? ?? {};
            final player = actionData['player_id'] != null 
                ? await _loadPlayer(actionData['player_id'] as String)
                : null;
                
            events.add(RallyEvent(
              id: actionData['id'] as String,
              type: _mapDbActionType(actionData['action_type'] as String),
              timestamp: DateTime.parse(actionData['recorded_at'] as String),
              player: player,
              note: metadata['note'] as String?,
            ));
          }
        }

        rallies.add(RallyRecord(
          rallyId: rallyData['id'] as String,
          rallyNumber: rallyData['rally_number'] as int,
          rotationNumber: (rallyData['rotation'] as int?) ?? 1,
          completedAt: DateTime.parse(rallyData['created_at'] as String),
          events: events,
        ));
      }

      return rallies;
    } catch (e) {
      throw RallyRepositoryException('Failed to load rallies: $e');
    }
  }

  /// Sync unsaved rally data when coming back online
  Future<void> syncPendingRallies(List<RallyRecord> pendingRallies) async {
    for (final rally in pendingRallies) {
      // This would need the match and set context - implement based on your app state
      // For now, this is a placeholder for the sync logic
    }
  }

  String _determineRallyResult(List<RallyEvent> events) {
    for (final event in events) {
      switch (event.type) {
        case RallyActionTypes.serveAce:
        case RallyActionTypes.firstBallKill:
        case RallyActionTypes.attackKill:
        case RallyActionTypes.block:
          return 'win';
        case RallyActionTypes.serveError:
        case RallyActionTypes.attackError:
          return 'error';
        case RallyActionTypes.attackAttempt:
        case RallyActionTypes.dig:
        case RallyActionTypes.assist:
        case RallyActionTypes.timeout:
        case RallyActionTypes.substitution:
          continue; // These don't determine rally result
      }
    }
    return 'loss'; // Default assumption
  }

  String _determineTransitionType(List<RallyEvent> events) {
    for (final event in events) {
      if (event.type == RallyActionTypes.firstBallKill) {
        return 'transition';
      }
    }
    return 'serve_receive'; // Default assumption
  }

  String _mapActionTypeToDb(RallyActionTypes type) {
    switch (type) {
      case RallyActionTypes.serveAce:
      case RallyActionTypes.serveError:
        return 'serve';
      case RallyActionTypes.firstBallKill:
      case RallyActionTypes.attackKill:
      case RallyActionTypes.attackError:
      case RallyActionTypes.attackAttempt:
        return 'attack';
      case RallyActionTypes.block:
        return 'block';
      case RallyActionTypes.dig:
        return 'dig';
      case RallyActionTypes.assist:
        return 'assist';
      default:
        return 'other';
    }
  }

  String? _mapActionSubtype(RallyActionTypes type) {
    switch (type) {
      case RallyActionTypes.serveAce:
        return 'ace';
      case RallyActionTypes.serveError:
        return 'error';
      case RallyActionTypes.firstBallKill:
        return 'first_ball_kill';
      case RallyActionTypes.attackKill:
        return 'kill';
      case RallyActionTypes.attackError:
        return 'error';
      case RallyActionTypes.attackAttempt:
        return 'attempt';
      case RallyActionTypes.block:
        return null;
      case RallyActionTypes.dig:
        return null;
      case RallyActionTypes.assist:
        return null;
      case RallyActionTypes.timeout:
        return null;
      case RallyActionTypes.substitution:
        return null;
    }
  }

  String _determineActionOutcome(RallyEvent event) {
    switch (event.type) {
      case RallyActionTypes.serveAce:
      case RallyActionTypes.firstBallKill:
      case RallyActionTypes.attackKill:
        return 'point';
      case RallyActionTypes.serveError:
      case RallyActionTypes.attackError:
        return 'error';
      case RallyActionTypes.attackAttempt:
        return 'in_play';
      case RallyActionTypes.block:
        return 'block_point';
      case RallyActionTypes.dig:
        return 'successful_dig';
      case RallyActionTypes.assist:
        return 'assist';
      case RallyActionTypes.timeout:
        return 'timeout';
      case RallyActionTypes.substitution:
        return 'substitution';
      default:
        return 'neutral';
    }
  }

  RallyActionTypes _mapDbActionType(String dbType) {
    switch (dbType) {
      case 'serve':
        return RallyActionTypes.serveAce; // Default for serves
      case 'attack':
        return RallyActionTypes.attackKill; // Default for attacks
      case 'block':
        return RallyActionTypes.block;
      case 'dig':
        return RallyActionTypes.dig;
      case 'assist':
        return RallyActionTypes.assist;
      default:
        return RallyActionTypes.serveAce; // Fallback
    }
  }

  Future<MatchPlayer?> _loadPlayer(String playerId) async {
    try {
      final response = await _client
          .from('players')
          .select('id, jersey_number, first_name, last_name, position')
          .eq('id', playerId)
          .single();
      
      return MatchPlayer(
        id: response['id'] as String,
        jerseyNumber: response['jersey_number'] as int,
        name: '${response['first_name']} ${response['last_name']}',
        position: response['position'] as String? ?? '',
      );
    } catch (e) {
      return null;
    }
  }
}

/// Exception thrown when rally repository operations fail
class RallyRepositoryException implements Exception {
  const RallyRepositoryException(this.message);
  
  final String message;
  
  @override
  String toString() => 'RallyRepositoryException: $message';
}
