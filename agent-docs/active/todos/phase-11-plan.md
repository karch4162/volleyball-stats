# Phase 11: History Dashboards & Match Analytics

## Overview

After completing the match setup flow (Phases 1-10), Phase 11 focuses on building history dashboards and match analytics to help coaches review past matches, analyze performance trends, and make data-driven decisions.

## Goals

1. **Match History View**: Display list of completed matches with key stats and quick access
2. **Match Recap Screen**: Detailed breakdown of a single match with set-by-set analysis
3. **Set Dashboard**: Live and historical set statistics with visual summaries
4. **Season Dashboard**: Aggregate statistics across multiple matches with filters
5. **Basic Analytics**: Key performance indicators (KPIs) and trends

## Tasks

### 1. Match History List Screen
**Goal:** Show all completed matches for the selected team with quick stats

**Features:**
- List of matches sorted by date (newest first)
- Display: opponent, date, score (sets won/lost), match result
- Quick stats: total rallies, FBK count, transition points
- Filter by: date range, opponent, season
- Search by opponent name
- Tap to view match recap

**Files to Create:**
- `app/lib/features/history/match_history_screen.dart`
- `app/lib/features/history/models/match_summary.dart`
- `app/lib/features/history/providers.dart`

**Files to Modify:**
- `app/lib/features/match_setup/match_setup_landing_screen.dart` - Add "Match History" option
- `app/lib/features/match_setup/data/match_setup_repository.dart` - Add method to fetch match summaries

**Database Queries:**
- Query `matches` table filtered by `team_id`
- Join with `sets` to get set scores
- Aggregate rally counts and action types
- Order by `match_date` DESC

---

### 2. Match Recap Screen
**Goal:** Detailed view of a single match with comprehensive statistics

**Features:**
- **Match Header**: Opponent, date, location, final score (sets won/lost)
- **Set Summary Cards**: Each set showing:
  - Score (our score - opponent score)
  - Rally count
  - FBK count
  - Transition points
  - Win/Loss indicator
- **Overall Match Stats**:
  - Total rallies
  - Total FBK
  - Total transition points
  - Substitutions used
  - Timeouts called
- **Per-Player Performance**:
  - Attack stats (kills, errors, attempts, efficiency)
  - Block stats (blocks, block errors)
  - Serve stats (aces, errors)
  - Total points contributed
- **Timeline View**: Rally-by-rally breakdown (optional, expandable)
- **Export Button**: Generate CSV/PDF for this match

**Files to Create:**
- `app/lib/features/history/match_recap_screen.dart`
- `app/lib/features/history/widgets/set_summary_card.dart`
- `app/lib/features/history/widgets/player_performance_card.dart`
- `app/lib/features/history/widgets/match_stats_summary.dart`

**Files to Modify:**
- `app/lib/features/match_setup/data/match_setup_repository.dart` - Add method to fetch full match details
- `app/lib/features/export/export_service.dart` - Add match-specific export

**Data Aggregation:**
- Load match with all sets
- For each set, aggregate rallies and actions
- Calculate per-player statistics from actions
- Compute efficiency ratios (attack efficiency, kill percentage)

---

### 3. Set Dashboard Screen
**Goal:** Visual dashboard showing set statistics and trends

**Features:**
- **Set Overview**: Current set score, rally count, time elapsed
- **Running Totals Bar**: FBK, Wins, Losses, Transition Points (reuse from rally capture)
- **Serve Rotation Summary**: 
  - Show each rotation (1-6) with serve efficiency
  - Display rotation order and player assignments
- **Point Flow Chart**: Visual representation of point scoring over time
- **Key Moments**: Highlight substitutions, timeouts, and significant rallies
- **Set Comparison**: Compare current set to previous sets in match

**Files to Create:**
- `app/lib/features/history/set_dashboard_screen.dart`
- `app/lib/features/history/widgets/rotation_summary_widget.dart`
- `app/lib/features/history/widgets/point_flow_chart.dart`

**Files to Modify:**
- `app/lib/features/rally_capture/rally_capture_screen.dart` - Add navigation to set dashboard
- `app/lib/features/rally_capture/providers.dart` - Expose set-level statistics

---

### 4. Season Dashboard Screen
**Goal:** Aggregate statistics across multiple matches with filtering

**Features:**
- **Season Overview**:
  - Total matches played
  - Overall win/loss record
  - Total sets won/lost
  - Win percentage
- **Team Statistics**:
  - Total FBK across all matches
  - Average FBK per match
  - Total transition points
  - Average rallies per match
- **Top Performers**:
  - Players with most kills
  - Players with highest attack efficiency
  - Players with most blocks
  - Players with most aces
- **Match Trends**:
  - Win/loss trend over time (chart)
  - FBK trend over time
  - Performance by opponent
- **Filters**:
  - Date range picker
  - Opponent filter (multi-select)
  - Season selector
  - Match type filter (if we add tournament/league types)

**Files to Create:**
- `app/lib/features/history/season_dashboard_screen.dart`
- `app/lib/features/history/widgets/season_overview_card.dart`
- `app/lib/features/history/widgets/top_performers_widget.dart`
- `app/lib/features/history/widgets/match_trends_chart.dart`
- `app/lib/features/history/widgets/season_filters.dart`

**Files to Modify:**
- `app/lib/features/match_setup/match_setup_landing_screen.dart` - Add "Season Dashboard" option
- `app/lib/features/match_setup/data/match_setup_repository.dart` - Add season aggregation methods

**Database Aggregation:**
- Query all matches for team within date range
- Aggregate statistics across matches
- Calculate per-player totals and averages
- Group by opponent for comparison

---

### 5. Basic Analytics & KPIs
**Goal:** Calculate and display key performance indicators

**KPIs to Track:**
- **FBK Percentage**: (FBK / Total Rallies) × 100
- **Transition Point Percentage**: (Transition Points / Total Rallies) × 100
- **Attack Efficiency**: (Kills - Errors) / Total Attempts
- **Kill Percentage**: Kills / Total Attempts
- **Block Efficiency**: Blocks / Total Attempts
- **Serve Efficiency**: (Aces - Errors) / Total Serves
- **Win Rate**: Matches Won / Total Matches

**Files to Create:**
- `app/lib/features/history/utils/analytics_calculator.dart`
- `app/lib/features/history/models/kpi_summary.dart`

**Files to Modify:**
- `app/lib/features/history/match_recap_screen.dart` - Display KPIs
- `app/lib/features/history/season_dashboard_screen.dart` - Display season KPIs

---

## Data Model Extensions

### Match Summary Model
```dart
class MatchSummary {
  final String matchId;
  final String opponent;
  final DateTime matchDate;
  final String location;
  final int setsWon;
  final int setsLost;
  final int totalRallies;
  final int totalFBK;
  final int totalTransitionPoints;
  final bool isWin; // true if setsWon > setsLost
}
```

### Set Summary Model
```dart
class SetSummary {
  final int setNumber;
  final int ourScore;
  final int opponentScore;
  final int rallyCount;
  final int fbkCount;
  final int transitionPoints;
  final bool isWin;
  final Duration? duration; // if we track time
}
```

### Player Performance Model
```dart
class PlayerPerformance {
  final String playerId;
  final String playerName;
  final int jerseyNumber;
  final int kills;
  final int errors;
  final int attempts;
  final double attackEfficiency;
  final double killPercentage;
  final int blocks;
  final int aces;
  final int totalPoints; // kills + blocks + aces
}
```

---

## Navigation Updates

**Add to Match Setup Landing Screen:**
- New card: "Match History" → navigates to `MatchHistoryScreen`
- New card: "Season Dashboard" → navigates to `SeasonDashboardScreen`

**Add to Rally Capture Screen:**
- Button/icon to view current set dashboard
- Access to match recap after match completion

---

## UI/UX Considerations

1. **Loading States**: Show skeleton loaders while fetching match data
2. **Empty States**: Friendly messages when no matches exist
3. **Error Handling**: Clear error messages if data fetch fails
4. **Performance**: Lazy load match details (only load full data when viewing recap)
5. **Caching**: Cache match summaries locally for offline viewing
6. **Visual Design**: Use charts and graphs for trends (consider `fl_chart` package)

---

## Testing Requirements

1. **Unit Tests**:
   - Analytics calculator functions
   - Data aggregation logic
   - KPI calculations

2. **Widget Tests**:
   - Match history list rendering
   - Match recap screen layout
   - Season dashboard filters

3. **Integration Tests**:
   - End-to-end flow: view match → see recap → check stats
   - Filter functionality on season dashboard
   - Export functionality

---

## Dependencies

**New Packages (if needed):**
- `fl_chart: ^0.68.0` - For charts and graphs (optional, can use simple widgets)
- `intl: ^0.19.0` - Already included for date formatting

**Existing Packages:**
- `flutter_riverpod` - State management
- `supabase_flutter` - Data fetching
- `hive` - Local caching

---

## Success Criteria

1. ✅ Coaches can view all their completed matches
2. ✅ Match recap shows comprehensive statistics
3. ✅ Season dashboard displays aggregate statistics
4. ✅ Filters work correctly (date range, opponent)
5. ✅ Analytics calculations are accurate
6. ✅ Performance is acceptable (<2s load time for match list)
7. ✅ Works offline (cached match summaries)

---

## Future Enhancements (Post-Phase 11)

- **Advanced Analytics**: Heat maps, player position analysis
- **Comparison Tools**: Compare matches side-by-side
- **Export Enhancements**: PDF reports with charts
- **Notifications**: Alerts for milestones (e.g., "100th FBK")
- **Sharing**: Share match summaries with other coaches
- **Video Integration**: Link video recordings to matches

---

## Estimated Timeline

- **Task 1 (Match History List)**: 2-3 days
- **Task 2 (Match Recap)**: 3-4 days
- **Task 3 (Set Dashboard)**: 2-3 days
- **Task 4 (Season Dashboard)**: 4-5 days
- **Task 5 (Analytics & KPIs)**: 2-3 days
- **Testing & Polish**: 2-3 days

**Total: ~15-20 days**

---

## Notes

- This phase assumes matches are being saved to Supabase after completion
- May need to enhance rally capture to ensure proper match completion and saving
- Consider adding match status (in-progress, completed, abandoned) if not already present
- Ensure RLS policies allow coaches to view their own match data

