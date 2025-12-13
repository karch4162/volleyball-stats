import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'providers.dart';
import '../rally_capture/providers.dart';

/// Screen for exporting data in various formats
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  static const routeName = '/export';

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(rallyCaptureStateProvider('current-match'));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(exportProvider.notifier).clearError();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match status
            if (matchState.hasValue) ...[
              _buildMatchInfo(context, matchState.value!),
              const SizedBox(height: 16),
            ] else ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No match in progress. Start a match to export data.'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Export options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Options',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildExportOption(
                      context,
                      'Rally Data',
                      'Export all rally data to CSV format',
                      Icons.list_alt,
                      () => _exportRalliesCsv('current-match'),
                    ),
                    _buildExportOption(
                      context,
                      'Player Statistics',
                      'Export player performance statistics',
                      Icons.people,
                      () => _exportPlayerStats(),
                    ),
                    // TODO: Add match summary option
                    _buildExportOption(
                      context,
                      'Match Summary',
                      'Export high-level match summary',
                      Icons.summarize,
                      () => _showNotImplemented('Match summary export'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Export status
            _buildExportStatus(context),
            
            const Spacer(),
            
            // Export history
            _buildExportHistory(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchInfo(BuildContext context, RallyCaptureState matchState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Match',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${matchState.draft.opponent} • ${matchState.draft.matchDate?.toIso8601String() ?? 'TBD'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final session = ref.watch(rallyCaptureSessionProvider('current-match'));
                return Text(
                  '${session.completedRallies.length} rallies completed',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              '${matchState.activePlayers.length} active players',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          onTap();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export completed successfully')),
            );
          }
        },
      ),
    );
  }

  Widget _buildExportStatus(BuildContext context) {
    final state = ref.watch(exportProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (state.isExporting) ...[
              const Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 8),
                  Text('Exporting data...'),
                ],
              ),
            ] else if (state.error != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Export failed: ${state.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Ready to export',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            if (state.exportCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Total exports: ${state.exportCount}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (state.lastExportTime != null) ...[
                Text(
                  'Last export: ${_formatDateTime(state.lastExportTime!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportHistory(BuildContext context) {
    final state = ref.watch(exportProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Exports',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            if (state.exportCount == 0) ...[
              Text(
                'No exports yet. Use the buttons above to export your data.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              Text(
                '${state.exportCount} export(s) completed',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Export action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await _exportAndShareRalliesCsv('current-match');
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Export & Share'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final csvContent = await ref
                        .read(exportProvider.notifier)
                        .exportRalliesToCsv(
                          matchId: 'current-match',
                        );
                    if (csvContent != null) {
                      final file = await ref
                          .read(exportServiceProvider)
                          .saveCsvToFile(
                            csvContent: csvContent,
                            filename: 'volleyball_stats_rallies',
                          );
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('CSV saved to device'),
                            action: SnackBarAction(
                              label: 'View',
                              onPressed: () => _showFileLocation(file.path),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save CSV'),
                ),
                TextButton.icon(
                  onPressed: () {
                    ref.read(exportProvider.notifier).clearError();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Status'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportRalliesCsv(String matchId) async {
    final csvContent = await ref
        .read(exportProvider.notifier)
        .exportRalliesToCsv(matchId: matchId);
    
    if (csvContent != null) {
      final file = await ref
          .read(exportServiceProvider)
          .saveCsvToFile(
            csvContent: csvContent,
            filename: 'volleyball_stats_rallies',
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('CSV saved to device'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _showFileLocation(file.path),
            ),
          ),
        );
      }
    }
  }

  Future<void> _exportAndShareRalliesCsv(String matchId) async {
    final csvContent = await ref
        .read(exportProvider.notifier)
        .exportRalliesToCsv(matchId: matchId);
    
    if (csvContent != null) {
      await ref
          .read(exportServiceProvider)
          .shareCsvFile(
            csvContent: csvContent,
            filename: 'volleyball_stats_rallies',
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV exported and sharing options opened'),
          ),
        );
      }
    }
  }

  void _showFileLocation(String filePath) async {
    // In a real app, you'd use share_plus or similar packages
    final uri = Uri.parse('file://$filePath');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file. You can find it at: $filePath')),
        );
      }
    }
  }

  Future<void> _exportPlayerStats() async {
    final csvContent = await ref
        .read(exportProvider.notifier)
        .exportPlayerStatsToCsv(teamId: 'default-team-id');
    
    if (csvContent != null) {
      await ref
          .read(exportServiceProvider)
          .saveCsvToFile(
            csvContent: csvContent,
            filename: 'volleyball_stats_players',
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player stats CSV saved to device')),
        );
      }
    }
  }

  void _showNotImplemented(String feature) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$feature coming soon!'),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.year.toString()} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
