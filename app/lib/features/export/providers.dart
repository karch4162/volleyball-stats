import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'csv_export_service.dart';
import 'export_service.dart';

/// Provider for export services
final exportServiceProvider = Provider<CsvExportService>((ref) {
  return const CsvExportService();
});

/// Provider for export functionality
final exportProvider = StateNotifierProvider<ExportNotifier, ExportState>(
  (ref) {
    return ExportNotifier(ref);
  },
);
