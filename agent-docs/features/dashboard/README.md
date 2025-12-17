# Dashboard Feature

## Overview

The Dashboard feature provides coaches with comprehensive views of match statistics, including set dashboards, match recaps, season aggregates, and player performance analysis.

## Status

✅ **Refactored** (Dashboard refactor complete)

Dashboard views refactored with improved data visualization and user experience.

## Key Features

### Set Dashboard
- Live set statistics during match
- Running totals display
- Serve rotation summary
- Point flow visualization
- Key moments (substitutions, timeouts)

### Match Recap
- Detailed single-match breakdown
- Set-by-set analysis
- Per-player performance statistics
- Attack efficiency, kill percentage
- Export functionality (CSV/PDF)

### Season Dashboard
- Aggregate statistics across matches
- Win/loss records
- Team performance trends
- Top performers by stat category
- Filters (date range, opponent, season)

### Player Statistics
- Individual player performance cards
- Attack stats (kills, errors, attempts, efficiency)
- Block stats, serve stats
- Sorting and filtering controls
- Performance comparisons

## Documentation

- **[Refactor Plan](refactor-plan.md)** - Dashboard refactor planning and goals
- **[Refactor Complete](refactor-complete.md)** - Completion notes and outcomes

## Related

- **Next Phase**: [Phase 11 Plan](../../active/todos/phase-11-plan.md) - History dashboards & match analytics
- **QA Report**: [QA Remediation Plan](../../reports/qa-remediation-plan.md) - Phase 3: Test Coverage

## Code Location

- `app/lib/features/history/` - Dashboard screens
- `app/lib/features/history/set_dashboard_screen.dart` - Set view
- `app/lib/features/history/match_recap_screen.dart` - Match view
- `app/lib/features/history/season_dashboard_screen.dart` - Season view
- `app/lib/features/history/widgets/` - Reusable dashboard widgets
- `app/lib/features/history/utils/analytics_calculator.dart` - KPI calculations

## Next Steps

Per [Phase 11 Plan](../../active/todos/phase-11-plan.md):
- Enhanced match history list
- Advanced analytics and KPIs
- Match trends visualization
- Comparison tools
- Export enhancements (PDF reports with charts)

