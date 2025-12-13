import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../teams/team_providers.dart';
import 'models/match_summary.dart';
import 'providers.dart';
import 'match_recap_screen.dart';

class MatchHistoryScreen extends ConsumerStatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  ConsumerState<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends ConsumerState<MatchHistoryScreen> {
  String? _searchQuery;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedSeason;

  @override
  Widget build(BuildContext context) {
    final selectedTeam = ref.watch(selectedTeamProvider);
    
    final params = MatchSummariesParams(
      startDate: _startDate,
      endDate: _endDate,
      opponent: _searchQuery?.isNotEmpty == true ? _searchQuery : null,
      seasonLabel: _selectedSeason,
    );

    final matchesAsync = ref.watch(matchSummariesProvider(params));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match History'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassLightContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by opponent...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                          onPressed: () {
                            setState(() {
                              _searchQuery = null;
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.isEmpty ? null : value;
                  });
                },
              ),
            ),
          ),

          // Active filters
          if (_startDate != null || _endDate != null || _selectedSeason != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_startDate != null)
                    Chip(
                      label: Text('From: ${DateFormat('MMM d').format(_startDate!)}'),
                      onDeleted: () {
                        setState(() {
                          _startDate = null;
                        });
                      },
                    ),
                  if (_endDate != null)
                    Chip(
                      label: Text('To: ${DateFormat('MMM d').format(_endDate!)}'),
                      onDeleted: () {
                        setState(() {
                          _endDate = null;
                        });
                      },
                    ),
                  if (_selectedSeason != null)
                    Chip(
                      label: Text('Season: $_selectedSeason'),
                      onDeleted: () {
                        setState(() {
                          _selectedSeason = null;
                        });
                      },
                    ),
                ],
              ),
            ),

          // Match list
          Expanded(
            child: matchesAsync.when(
              data: (matches) {
                if (matches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.sports_volleyball_outlined,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No matches found',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedTeam == null
                              ? 'Select a team to view match history'
                              : 'Try adjusting your filters or start a new match',
                          style: const TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MatchCard(match: match),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: AppColors.rose,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading matches',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(matchSummariesProvider(params));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Filter Matches',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textMuted,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(
                        _startDate != null
                            ? DateFormat('MMM d, y').format(_startDate!)
                            : 'No date selected',
                      ),
                      trailing: const Icon(Icons.calendar_today_rounded),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null && mounted) {
                          setState(() {
                            _startDate = date;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(
                        _endDate != null
                            ? DateFormat('MMM d, y').format(_endDate!)
                            : 'No date selected',
                      ),
                      trailing: const Icon(Icons.calendar_today_rounded),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null && mounted) {
                          setState(() {
                            _endDate = date;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('Season'),
                      subtitle: Text(_selectedSeason ?? 'All seasons'),
                      trailing: const Icon(Icons.arrow_drop_down_rounded),
                      onTap: () {
                        // Would show season picker
                        // For now, just allow clearing
                        if (_selectedSeason != null) {
                          setState(() {
                            _selectedSeason = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final MatchSummary match;

  @override
  Widget build(BuildContext context) {
    return GlassLightContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MatchRecapScreen(matchId: match.matchId),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.opponent,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, y').format(match.matchDate),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: match.isWin
                      ? AppColors.emerald.withOpacity(0.2)
                      : AppColors.rose.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: match.isWin ? AppColors.emerald : AppColors.rose,
                    width: 1,
                  ),
                ),
                child: Text(
                  match.isWin ? 'WIN' : 'LOSS',
                  style: TextStyle(
                    color: match.isWin ? AppColors.emerald : AppColors.rose,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                icon: Icons.sports_volleyball_rounded,
                label: '${match.setsWon}-${match.setsLost}',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.timeline_rounded,
                label: '${match.totalRallies} rallies',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.star_rounded,
                label: '${match.totalFBK} FBK',
              ),
            ],
          ),
          if (match.location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              match.location,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

