import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../rally_capture/models/rally_models.dart';
import '../rally_capture/providers.dart';
import '../match_setup/providers.dart';
import 'providers.dart';

/// Export state management
class ExportNotifier extends StateNotifier<ExportState> {
  ExportNotifier(this.ref) : super(const ExportState());
  
  final Ref ref;

  /// Export rallies to CSV
  Future<String?> exportRalliesToCsv({
    required String matchId,
  }) async {
    state = state.copyWith(isExporting: true, error: null);
    
    try {
      // Get rally session data
      final session = await _getRallySessionData(matchId);
      if (session == null) {
        state = state.copyWith(
          isExporting: false,
          error: 'No rally data found',
        );
        return null;
      }

      // Get match and player data
      final matchState = await ref.read(rallyCaptureStateProvider(matchId).future);
      final players = await ref.read(matchSetupRosterProvider.future);
      
      final csvService = ref.watch(exportServiceProvider);
      final csvContent = await csvService.exportRalliesToCsv(
        rallies: session.completedRallies,
        players: players,
        opponent: matchState.draft.opponent,
        matchDate: matchState.draft.matchDate,
      );

      state = state.copyWith(
        isExporting: false,
        lastExportTime: DateTime.now(),
      );
      
      return csvContent;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Export player stats to CSV
  Future<String?> exportPlayerStatsToCsv({
    required String teamId,
  }) async {
    state = state.copyWith(isExporting: true, error: null);
    
    try {
      // This would need to be implemented to get all rallies for the team
      // For now, return a placeholder
      final players = await ref.read(matchSetupRosterProvider.future);
      final rallyRecords = <RallyRecord>[]; // Would get from match history
      
      final csvService = ref.watch(exportServiceProvider);
      return await csvService.exportPlayerStatsToCsv(
        players: players,
        rallies: rallyRecords,
        seasonTotals: null, // Optional season totals
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Share CSV file
  Future<void> shareRalliesCsv({
    required String matchId,
    required String filename,
  }) async {
    final csvContent = await exportRalliesToCsv(matchId: matchId);
    if (csvContent != null) {
      await ref.watch(exportServiceProvider).shareCsvFile(
        csvContent: csvContent,
        filename: filename,
      );
      
      state = state.copyWith(
        lastExportTime: DateTime.now(),
        exportCount: state.exportCount + 1,
      );
    }
  }

  /// Clear any export state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get export statistics
  int get exportCount => state.exportCount;
  DateTime? getLastExportTime() => state.lastExportTime;

  /// Private helper to get rally session data (placeholder)
  Future<RallyCaptureSession?> _getRallySessionData(String matchId) async {
    // This is a placeholder - in a real implementation, you'd get the actual session data
    try {
      final session = ref.read(rallyCaptureSessionProvider(matchId));
      return session;
    } catch (e) {
      return null;
    }
  }
}

/// Export state
class ExportState {
  const ExportState({
    this.isExporting = false,
    this.error,
    this.lastExportTime,
    this.exportCount = 0,
  });

  final bool isExporting;
  final String? error;
  final DateTime? lastExportTime;
  final int exportCount;

  ExportState copyWith({
    bool? isExporting,
    String? error,
    DateTime? lastExportTime,
    int? exportCount,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      error: error,
      lastExportTime: lastExportTime ?? this.lastExportTime,
      exportCount: exportCount ?? this.exportCount,
    );
  }
}
