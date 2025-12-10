# Dashboard Refactor Plan: Player-Focused Analytics

**Created:** 2025-12-10  
**Status:** Planning Phase  
**Author:** Senior Flutter Engineer

---

## Executive Summary

This document outlines a comprehensive refactor of the dashboard views (Set, Match, and Season) to transition from rally-focused displays to **player-focused analytics**. The goal is to provide coaches with immediate insights into individual player performance at different aggregation levels (set, match, season), making it easier to evaluate substitution decisions, player development, and team strategy.

---

## Current State Analysis

### Set Dashboard (`set_dashboard_screen.dart`)
- **Top Section:** Running totals display (FBK, Wins, Losses, Transition Points) ✅ Keep
- **Bottom Section:** Rally breakdown showing individual rallies with events ❌ Remove
- **Missing:** No player-level statistics breakdown

### Season Dashboard (`season_dashboard_screen.dart`)
- **Filters:** Date range, season selection ✅ Keep
- **Season Overview:** Matches won/lost, sets won/lost, win rate ✅ Keep
- **Team Statistics:** Total FBK, avg FBK per match, transition points, rallies ✅ Keep
- **Top Performers:** Displays top players by kills, attack efficiency, blocks, aces ✅ Enhance
- **Missing:** Comprehensive per-player breakdown with all requested metrics

### Match Recap (`match_recap_screen.dart`)
- **Match Header:** Opponent, date, location, win/loss record ✅ Keep
- **Set Summaries:** Individual set scores and stats ✅ Keep
- **Match Statistics:** Total rallies, FBK, transition points, subs, timeouts ✅ Keep
- **Player Performances:** Currently empty/not fully implemented ❌ Needs implementation

### Data Model (`PlayerPerformance`)
**Currently Tracked:**
- Kills, Errors, Attempts
- Attack Efficiency: (Kills - Errors) / Attempts
- Kill Percentage: Kills / Attempts
- Blocks, Aces
- Total Points: Kills + Blocks + Aces

**Available but Not Displayed:**
- Digs (from `PlayerStats`)
- Assists (from `PlayerStats`)
- First Ball Kills (from `PlayerStats`)
- Service Errors (from `PlayerStats`)

---

## Requirements

### User Requirements
1. **Keep Totals at Top** - Maintain running totals display (FBK, Wins, Losses, Transition Points)
2. **Remove Rally Breakdown** - Replace with player statistics table/cards
3. **Player Metrics** (Required):
   - Hitting Percentage (Kill %)
   - Service Pressure
   - First Ball Kills
   - Blocks
   - Assists
4. **Aggregation Levels** - Metrics calculated by set, match, and season
5. **Handle Non-Playing Players** - Show 0s for players who didn't participate in a set

### Additional Recommended Metrics
Based on volleyball analytics best practices and available data:

1. **Attack Efficiency** - (Kills - Errors) / Total Attempts [More comprehensive than kill %]
2. **Total Points** - Kills + Blocks + Aces [Overall offensive contribution]
3. **Digs** - Defensive contribution
4. **Service Aces** - Successful aggressive serves [Component of service pressure]
5. **Service Errors** - Risk metric for service pressure
6. **Service Pressure Rating** - Calculated metric: (Aces - Errors) / Total Serves or Ace %
7. **Attack Attempts** - Activity level indicator
8. **Total Serves** - Service activity level

---

## Proposed Design

### Dashboard Layout Structure

```
┌─────────────────────────────────────────┐
│         SET/MATCH/SEASON DASHBOARD       │
├─────────────────────────────────────────┤
│                                         │
│  📊 RUNNING TOTALS (Keep Current)      │
│     FBK | Wins | Losses | Trans Pts    │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  👥 PLAYER PERFORMANCE                  │
│                                         │
│  [Sort By: Points ▼] [Filter ▼]        │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ #12 Smith, Sarah                │   │
│  │ ─────────────────────────────── │   │
│  │ Attack: 15K-3E / 25A (48.0%)   │   │
│  │ Efficiency: 0.480               │   │
│  │ Service: 3A-1E / 12S (25.0%)   │   │
│  │ Other: 5B | 8D | 12Ast | 4FBK  │   │
│  │ Total Points: 23                │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ #8 Johnson, Emma                │   │
│  │ ─────────────────────────────── │   │
│  │ Attack: 12K-2E / 20A (60.0%)   │   │
│  │ ... (similar layout)            │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ... (more player cards)                │
│                                         │
└─────────────────────────────────────────┘
```

### Player Card Design (Detailed)

```dart
┌──────────────────────────────────────────────────┐
│ #12  Smith, Sarah                     [Expand ▼] │
├──────────────────────────────────────────────────┤
│                                                  │
│ ATTACKING                                        │
│ • Kills: 15        • Errors: 3                   │
│ • Attempts: 25     • Kill %: 48.0%               │
│ • Attack Efficiency: 0.480                       │
│                                                  │
│ SERVING                                          │
│ • Aces: 3          • Errors: 1                   │
│ • Total Serves: 12 • Ace %: 25.0%                │
│ • Service Pressure: +16.7% (calculated)          │
│                                                  │
│ OTHER CONTRIBUTIONS                              │
│ • Blocks: 5        • Digs: 8                     │
│ • Assists: 12      • FBK: 4                      │
│                                                  │
│ SUMMARY                                          │
│ • Total Points: 23 (15K + 5B + 3A)               │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## Implementation Plan

### Phase 1: Data Layer Updates

#### 1.1 Enhance `PlayerPerformance` Model
**File:** `app/lib/features/history/models/player_performance.dart`

**Changes:**
```dart
class PlayerPerformance {
  // Existing fields
  final String playerId;
  final String playerName;
  final int jerseyNumber;
  final int kills;
  final int errors;
  final int attempts;
  final int blocks;
  final int aces;
  
  // NEW: Add missing fields
  final int digs;
  final int assists;
  final int fbk; // First Ball Kills
  final int serveAces; // Rename 'aces' usage for clarity
  final int serveErrors;
  final int totalServes;
  final int attackAttempts; // Explicit for clarity
  
  // Calculated metrics (computed properties)
  double get attackEfficiency => attempts > 0 ? (kills - errors) / attempts : 0.0;
  double get killPercentage => attempts > 0 ? kills / attempts : 0.0;
  double get acePercentage => totalServes > 0 ? serveAces / totalServes : 0.0;
  double get servicePressure => totalServes > 0 ? (serveAces - serveErrors) / totalServes : 0.0;
  int get totalPoints => kills + blocks + serveAces;
  
  // Formatted display strings
  String get attackSummary => '$kills-$errors / $attempts (${(killPercentage * 100).toStringAsFixed(1)}%)';
  String get serveSummary => '$serveAces-$serveErrors / $totalServes (${(acePercentage * 100).toStringAsFixed(1)}%)';
}
```

**Rationale:**
- Consolidate all player metrics into one model
- Add calculated properties for derived metrics
- Provide formatted strings for UI consistency
- Clear separation between raw counts and percentages

#### 1.2 Update Data Providers
**File:** `app/lib/features/history/providers.dart`

**Changes:**

**A) Add Set-Level Player Stats Provider**
```dart
final setPlayerStatsProvider = FutureProvider.family<List<PlayerPerformance>, SetPlayerStatsParams>(
  (ref, params) async {
    final repository = ref.watch(matchSetupRepositoryProvider);
    final roster = ref.watch(matchSetupRosterProvider).value ?? [];
    
    final stats = await repository.fetchSetPlayerStats(
      matchId: params.matchId,
      setNumber: params.setNumber,
    );
    
    return _buildPlayerPerformances(roster, stats);
  },
);

class SetPlayerStatsParams {
  final String matchId;
  final int setNumber;
  // ... equality operators
}
```

**B) Update Match-Level Stats Provider**
```dart
// Enhance matchDetailsProvider to include full player performances
// Already exists but needs to populate playerPerformances list
```

**C) Update Season Stats Provider**
```dart
// Already partially implemented in seasonStatsProvider
// Ensure it returns complete PlayerPerformance objects with all fields
```

**D) Helper Function for Building PlayerPerformance**
```dart
List<PlayerPerformance> _buildPlayerPerformances(
  List<MatchPlayer> roster,
  Map<String, Map<String, int>> statsMap,
) {
  return roster.map((player) {
    final stats = statsMap[player.id] ?? {};
    
    return PlayerPerformance(
      playerId: player.id,
      playerName: player.name,
      jerseyNumber: player.jerseyNumber,
      kills: stats['kills'] ?? 0,
      errors: stats['errors'] ?? 0,
      attempts: stats['attempts'] ?? 0,
      blocks: stats['blocks'] ?? 0,
      digs: stats['digs'] ?? 0,
      assists: stats['assists'] ?? 0,
      fbk: stats['fbk'] ?? 0,
      serveAces: stats['aces'] ?? 0,
      serveErrors: stats['serve_errors'] ?? 0,
      totalServes: (stats['aces'] ?? 0) + (stats['serve_errors'] ?? 0),
      attackAttempts: stats['attempts'] ?? 0,
    );
  }).toList();
}
```

**Rationale:**
- Consistent data fetching across all dashboard levels
- Handle non-playing players (0 stats)
- Reusable helper function for transforming data
- Type-safe parameter passing with family providers

#### 1.3 Update Repository Methods
**File:** `app/lib/features/match_setup/data/match_setup_repository.dart`

**Add New Method:**
```dart
Future<Map<String, Map<String, int>>> fetchSetPlayerStats({
  required String matchId,
  required int setNumber,
}) async {
  // Query Supabase for actions in a specific set
  // Aggregate by player_id
  // Return map of playerId -> stats map
}
```

**Enhance Existing Methods:**
- Ensure `fetchMatchDetails` includes complete player stats with new fields
- Ensure `fetchSeasonStats` includes digs, assists, fbk in aggregation

**Rationale:**
- Database queries should handle aggregation efficiently
- Return structured data ready for model transformation
- Include all action types (digs, assists, fbk)

---

### Phase 2: UI Component Development

#### 2.1 Create New Player Performance Card Widget
**File:** `app/lib/features/history/widgets/player_performance_card_v2.dart`

**Purpose:** Comprehensive player stats card with collapsible sections

**Structure:**
```dart
class PlayerPerformanceCardV2 extends StatefulWidget {
  final PlayerPerformance performance;
  final bool expandedByDefault;
  
  // Displays:
  // - Header: Jersey #, Name, Total Points
  // - Attacking section (kills, errors, attempts, efficiency, kill %)
  // - Serving section (aces, errors, serves, pressure rating)
  // - Other contributions (blocks, digs, assists, FBK)
  // - Expandable/collapsible for screen space management
}
```

**Features:**
- Glass morphism theme matching app design
- Color-coded metrics (green for positive, red for negative)
- Tap to expand/collapse details
- Sort indicators for top performers
- Visual badges for standout stats (e.g., "Top Scorer")

**Rationale:**
- Reusable across set, match, and season dashboards
- Consistent UI/UX
- Optimized for mobile screen space
- Accessible stat reading during live matches

#### 2.2 Create Player Stats Table Widget (Alternative View)
**File:** `app/lib/features/history/widgets/player_stats_table.dart`

**Purpose:** Compact table view for comparing multiple players at once

**Structure:**
```dart
class PlayerStatsTable extends StatelessWidget {
  final List<PlayerPerformance> players;
  final String sortBy; // 'points', 'kills', 'efficiency', 'blocks', etc.
  final bool ascending;
  
  // Displays horizontal scrollable table with columns:
  // | # | Name | K | E | A | Eff | B | D | Ast | FBK | Pts |
}
```

**Features:**
- Sortable columns (tap header to sort)
- Horizontal scroll for many columns
- Sticky first column (player name)
- Alternating row colors for readability
- Highlight top 3 performers per category

**Rationale:**
- Alternative view for coaches who prefer tables
- Easy cross-player comparison
- Familiar format (like spreadsheets)
- Good for tablets/landscape mode

#### 2.3 Create Stats Filter/Sort Widget
**File:** `app/lib/features/history/widgets/player_stats_controls.dart`

**Purpose:** Control bar for sorting and filtering player list

**Structure:**
```dart
class PlayerStatsControls extends StatelessWidget {
  final String currentSortBy;
  final bool ascending;
  final Function(String) onSortChanged;
  final Function(bool) onViewModeChanged; // Cards vs Table
  
  // Displays:
  // - Sort dropdown (Points, Kills, Efficiency, Blocks, etc.)
  // - Sort order toggle (asc/desc)
  // - View mode toggle (cards vs table)
  // - Optional: Filter by position, playing time, etc.
}
```

**Rationale:**
- User control over data presentation
- Quick access to different insights
- Consistent across all dashboard levels

---

### Phase 3: Screen Refactoring

#### 3.1 Refactor Set Dashboard
**File:** `app/lib/features/history/set_dashboard_screen.dart`

**Changes:**

**KEEP:**
- App bar with "Set X Dashboard" title
- Top section: Running totals (FBK, Wins, Losses, Transition Points)

**REMOVE:**
- `Rally Breakdown` section
- `_RallyCard` widget

**ADD:**
```dart
// After running totals:
PlayerStatsControls(
  currentSortBy: _sortBy,
  onSortChanged: (sort) => setState(() => _sortBy = sort),
  // ...
),
SizedBox(height: 16),

// Player performance section:
Consumer(
  builder: (context, ref, child) {
    final playerStatsAsync = ref.watch(setPlayerStatsProvider(SetPlayerStatsParams(
      matchId: matchId,
      setNumber: setNumber,
    )));
    
    return playerStatsAsync.when(
      data: (players) {
        final sortedPlayers = _sortPlayers(players, _sortBy);
        
        return Column(
          children: [
            Text('Player Performance', style: ...),
            SizedBox(height: 12),
            ...sortedPlayers.map((p) => PlayerPerformanceCardV2(performance: p)),
          ],
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(...),
    );
  },
),
```

**New State Variables:**
```dart
class _SetDashboardScreenState extends ConsumerState<SetDashboardScreen> {
  String _sortBy = 'points'; // Default sort
  bool _ascending = false; // Descending by default (highest first)
  bool _cardView = true; // Cards vs table view
  
  // ...
}
```

**Helper Methods:**
```dart
List<PlayerPerformance> _sortPlayers(List<PlayerPerformance> players, String sortBy) {
  final sorted = List<PlayerPerformance>.from(players);
  
  switch (sortBy) {
    case 'points':
      sorted.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      break;
    case 'kills':
      sorted.sort((a, b) => b.kills.compareTo(a.kills));
      break;
    case 'efficiency':
      sorted.sort((a, b) => b.attackEfficiency.compareTo(a.attackEfficiency));
      break;
    case 'blocks':
      sorted.sort((a, b) => b.blocks.compareTo(a.blocks));
      break;
    // ... more cases
  }
  
  return _ascending ? sorted.reversed.toList() : sorted;
}
```

**Rationale:**
- Maintains familiar top section
- Replaces rally details with actionable player insights
- Allows coaches to quickly identify top performers
- Sortable for different analysis needs

#### 3.2 Refactor Match Recap Screen
**File:** `app/lib/features/history/match_recap_screen.dart`

**Changes:**

**KEEP:**
- Match header (opponent, date, location, win/loss)
- Set summaries
- Match statistics (totals)

**ENHANCE:**
```dart
// Player performances section (currently empty):
if (details.playerPerformances.isNotEmpty) ...[
  PlayerStatsControls(...),
  SizedBox(height: 12),
  
  // Tabbed view for different insights:
  DefaultTabController(
    length: 3,
    child: Column(
      children: [
        TabBar(
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Attacking'),
            Tab(text: 'Serving'),
          ],
        ),
        // Overview tab: All players with key stats
        // Attacking tab: Focus on attack metrics, sorted by efficiency
        // Serving tab: Focus on serving metrics, sorted by aces
      ],
    ),
  ),
],
```

**Rationale:**
- Populate the currently empty player performances section
- Provide multiple views for different coaching focuses
- Match-level aggregation helps evaluate overall performance

#### 3.3 Refactor Season Dashboard
**File:** `app/lib/features/history/season_dashboard_screen.dart`

**Changes:**

**KEEP:**
- Filters (date range, season selection)
- Season overview (matches, sets, win rate)
- Team statistics

**ENHANCE:**
```dart
// Replace "Top Performers" section with comprehensive player table:
PlayerStatsControls(
  currentSortBy: _sortBy,
  viewMode: _viewMode, // Table view better for season-level
  // ...
),

// Show all players with season totals:
if (_viewMode == ViewMode.table) {
  PlayerStatsTable(
    players: allPlayerPerformances,
    sortBy: _sortBy,
    // ...
  ),
} else {
  // Card view
  ...allPlayerPerformances.map((p) => PlayerPerformanceCardV2(performance: p)),
}

// Add quick stats: Top 5 in each category as chips/badges
Row(
  children: [
    _TopPerformerChip(category: 'Kills', player: topKills.first),
    _TopPerformerChip(category: 'Efficiency', player: topEfficiency.first),
    // ...
  ],
),
```

**Rationale:**
- Season level benefits from table view (more data)
- Keep quick insights with top performer badges
- Full player list allows tracking development over time

---

### Phase 4: Database Queries & Performance

#### 4.1 Add Indexed Queries
**File:** `supabase/migrations/0005_player_stats_indices.sql`

```sql
-- Index for efficient player stat queries by set
CREATE INDEX IF NOT EXISTS idx_actions_set_player 
ON actions (rally_id, player_id, action_type);

-- Index for efficient aggregation by match
CREATE INDEX IF NOT EXISTS idx_rallies_match 
ON rallies (set_id) INCLUDE (result, transition_type);

-- Index for season-level queries
CREATE INDEX IF NOT EXISTS idx_matches_season 
ON matches (team_id, season_label, match_date);
```

**Rationale:**
- Optimize queries for player stat aggregation
- Reduce query time for season-level analytics
- Support efficient filtering by date, season, opponent

#### 4.2 Add Materialized Views (Optional for Performance)
**File:** `supabase/migrations/0006_materialized_views.sql`

```sql
-- Pre-aggregated player stats per set
CREATE MATERIALIZED VIEW IF NOT EXISTS player_set_stats AS
SELECT 
  p.id as player_id,
  s.id as set_id,
  s.match_id,
  s.set_number,
  COUNT(CASE WHEN a.action_subtype = 'kill' AND a.action_type = 'attack' THEN 1 END) as kills,
  COUNT(CASE WHEN a.action_subtype = 'error' AND a.action_type = 'attack' THEN 1 END) as errors,
  COUNT(CASE WHEN a.action_type = 'attack' THEN 1 END) as attempts,
  COUNT(CASE WHEN a.action_type = 'block' THEN 1 END) as blocks,
  COUNT(CASE WHEN a.action_type = 'dig' THEN 1 END) as digs,
  COUNT(CASE WHEN a.action_type = 'assist' THEN 1 END) as assists,
  COUNT(CASE WHEN a.outcome = 'first_ball_kill' THEN 1 END) as fbk,
  COUNT(CASE WHEN a.action_subtype = 'ace' AND a.action_type = 'serve' THEN 1 END) as aces,
  COUNT(CASE WHEN a.action_subtype = 'error' AND a.action_type = 'serve' THEN 1 END) as serve_errors
FROM players p
CROSS JOIN sets s
LEFT JOIN rallies r ON r.set_id = s.id
LEFT JOIN actions a ON a.rally_id = r.id AND a.player_id = p.id
WHERE s.match_id IN (SELECT id FROM matches WHERE team_id = p.team_id)
GROUP BY p.id, s.id, s.match_id, s.set_number;

-- Refresh strategy (trigger on action insert/update)
CREATE OR REPLACE FUNCTION refresh_player_set_stats()
RETURNS TRIGGER AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY player_set_stats;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER refresh_player_stats_trigger
AFTER INSERT OR UPDATE OR DELETE ON actions
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_player_set_stats();
```

**Rationale:**
- Dramatically speeds up dashboard loading
- Pre-computed aggregations reduce real-time calculation
- Can be refreshed incrementally or on-demand
- Trade-off: Slight delay in stat updates (acceptable for analytics)

---

### Phase 5: Testing & Validation

#### 5.1 Unit Tests
**Files:**
- `test/features/history/models/player_performance_test.dart`
- `test/features/history/providers_test.dart`

**Test Cases:**
1. **PlayerPerformance Calculations**
   - Attack efficiency formula correctness
   - Service pressure calculation
   - Total points summation
   - Edge cases (0 attempts, 0 serves)

2. **Data Providers**
   - Set-level stats fetch correct data
   - Match-level aggregation sums all sets
   - Season-level aggregation filters by date/season
   - Non-playing players return 0 stats

3. **Sorting Logic**
   - Sort by different metrics (points, kills, efficiency)
   - Ascending/descending order
   - Tie-breaking (e.g., by jersey number)

#### 5.2 Widget Tests
**Files:**
- `test/features/history/widgets/player_performance_card_v2_test.dart`
- `test/features/history/widgets/player_stats_table_test.dart`

**Test Cases:**
1. **PlayerPerformanceCardV2**
   - Displays all stat categories
   - Expand/collapse functionality
   - Formatting of percentages (1 decimal place)
   - Color coding for metrics

2. **PlayerStatsTable**
   - All columns render correctly
   - Sorting works on tap
   - Horizontal scroll enabled
   - Sticky column behavior

3. **PlayerStatsControls**
   - Sort dropdown changes state
   - View mode toggle switches between cards/table
   - Callbacks fire correctly

#### 5.3 Integration Tests
**Files:**
- `integration_test/dashboard_flow_test.dart`

**Test Flows:**
1. **Set Dashboard Flow**
   - Navigate to set dashboard
   - Verify running totals display
   - Verify player list displays
   - Change sort order
   - Expand/collapse player cards

2. **Match Recap Flow**
   - Navigate to match recap
   - Verify all sets are shown
   - Verify player performances are shown
   - Switch between overview/attacking/serving tabs

3. **Season Dashboard Flow**
   - Apply date filters
   - Verify player stats update
   - Switch between card/table view
   - Export functionality (future)

#### 5.4 Manual Testing Checklist
- [ ] Set dashboard loads with correct data
- [ ] Players who didn't play show 0s
- [ ] Sorting works for all categories
- [ ] Expand/collapse animations smooth
- [ ] Glass theme styling consistent
- [ ] Mobile layout responsive
- [ ] Tablet layout uses table view effectively
- [ ] Match dashboard aggregates sets correctly
- [ ] Season dashboard filters work
- [ ] No performance lag with 15+ players
- [ ] Offline mode displays cached data
- [ ] Sync indicator shows when updating

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────┐
│                    SUPABASE                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
│  │ matches  │  │   sets   │  │ rallies  │         │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘         │
│        │             │              │               │
│        └─────────────┴──────────────┘               │
│                      │                               │
│               ┌──────▼──────┐                       │
│               │   actions   │                       │
│               │ (player_id, │                       │
│               │  action_    │                       │
│               │  type, ...)  │                       │
│               └──────┬──────┘                       │
└──────────────────────┼──────────────────────────────┘
                       │
                       │ Repository queries
                       │ (aggregate by player)
                       │
         ┌─────────────▼──────────────┐
         │  match_setup_repository    │
         │  .fetchSetPlayerStats()    │
         │  .fetchMatchDetails()      │
         │  .fetchSeasonStats()       │
         └─────────────┬──────────────┘
                       │
                       │ Returns Map<playerId, stats>
                       │
         ┌─────────────▼──────────────┐
         │     Providers              │
         │  setPlayerStatsProvider    │
         │  matchDetailsProvider      │
         │  seasonStatsProvider       │
         └─────────────┬──────────────┘
                       │
                       │ Transforms to List<PlayerPerformance>
                       │
         ┌─────────────▼──────────────┐
         │  Dashboard Screens         │
         │  - SetDashboardScreen      │
         │  - MatchRecapScreen        │
         │  - SeasonDashboardScreen   │
         └─────────────┬──────────────┘
                       │
                       │ Displays via widgets
                       │
         ┌─────────────▼──────────────┐
         │  UI Widgets                │
         │  - PlayerPerformanceCardV2 │
         │  - PlayerStatsTable        │
         │  - PlayerStatsControls     │
         └────────────────────────────┘
```

---

## Metrics Definitions

### Attacking Metrics
| Metric | Formula | Description |
|--------|---------|-------------|
| **Kills (K)** | Count of successful attacks | Attacks that result in immediate points |
| **Errors (E)** | Count of attack errors | Attacks that result in opponent points |
| **Attempts (A)** | Count of all attacks | Total attack actions (K + E + other) |
| **Kill Percentage** | `(K / A) * 100` | Percentage of attacks that are kills |
| **Attack Efficiency** | `((K - E) / A)` | Net effectiveness, accounting for errors |

### Serving Metrics
| Metric | Formula | Description |
|--------|---------|-------------|
| **Aces** | Count of serve aces | Serves that result in immediate points |
| **Serve Errors** | Count of serve errors | Serves that go out or into net |
| **Total Serves** | `Aces + Errors + Other` | All service attempts |
| **Ace Percentage** | `(Aces / Total Serves) * 100` | Percentage of serves that are aces |
| **Service Pressure** | `((Aces - Errors) / Total Serves) * 100` | Net service effectiveness |

### Other Metrics
| Metric | Description |
|--------|-------------|
| **Blocks (B)** | Successful blocks at the net |
| **Digs (D)** | Successful defensive digs |
| **Assists (Ast)** | Successful sets leading to kills |
| **First Ball Kills (FBK)** | Kills immediately after serve receive |
| **Total Points** | `Kills + Blocks + Aces` (direct scoring) |

---

## UI/UX Considerations

### Mobile Optimization
- **Collapsible Cards:** Save screen space, show ~3-4 players at once
- **Swipeable Tabs:** Easy navigation between attacking/serving/other
- **Pull to Refresh:** Update stats without full reload
- **Sticky Headers:** Keep sorting controls visible while scrolling

### Tablet/Landscape Optimization
- **Table View Default:** More columns visible
- **Side-by-Side:** Running totals + player table in split view
- **Multi-Column Layout:** 2-3 player cards side-by-side

### Accessibility
- **Semantic Labels:** Screen reader support for all stats
- **Color + Text:** Don't rely solely on color for meaning
- **Font Scaling:** Respect system font size settings
- **Tap Targets:** Minimum 44x44pt touch areas

### Performance
- **Lazy Loading:** Load player cards as user scrolls
- **Memoization:** Cache calculated metrics
- **Debounced Sorting:** Prevent excessive re-renders
- **Skeleton Screens:** Show loading placeholders

---

## Migration Strategy

### Phase 1: Parallel Development (Week 1-2)
- Develop new components alongside existing screens
- Create feature flag `use_new_player_dashboard`
- Test with subset of users

### Phase 2: Soft Launch (Week 3)
- Enable new dashboard for internal testing
- Collect feedback from coaches
- Iterate on design based on usability

### Phase 3: Full Rollout (Week 4)
- Enable for all users
- Remove old rally breakdown code
- Update documentation and tutorials

### Rollback Plan
- Keep old code in separate file (`set_dashboard_screen_legacy.dart`)
- Feature flag to revert if critical issues
- Monitor error rates and user feedback

---

## Success Metrics

### User Engagement
- **Dashboard View Time:** Increase in time spent on dashboard (indicates usefulness)
- **Sort/Filter Usage:** Track how often coaches change views
- **Repeat Visits:** Measure return visits to dashboard after matches

### Performance
- **Load Time:** < 2s for set dashboard, < 3s for season dashboard
- **Scroll Performance:** 60fps with 15+ players
- **Memory Usage:** < 100MB additional heap

### User Feedback
- **Survey Rating:** > 4.5/5 for new dashboard
- **Feature Requests:** Track requests for additional metrics
- **Bug Reports:** < 5 critical bugs in first month

---

## Future Enhancements (Post-MVP)

### Advanced Analytics
- **Player Trends:** Line charts showing performance over time
- **Comparison Mode:** Side-by-side player comparison
- **Heatmaps:** Court position data for attacks/serves
- **Rotation Analysis:** Performance by rotation position

### Export & Sharing
- **PDF Export:** Generate printable player reports
- **CSV Export:** Export stats for external analysis (Excel, Google Sheets)
- **Share Cards:** Social media-ready player stat cards
- **Email Reports:** Automated weekly/season summaries

### AI/ML Features
- **Performance Predictions:** Suggest optimal lineups
- **Substitution Alerts:** Notify when player fatigue detected
- **Benchmarking:** Compare against league averages
- **Injury Risk:** Flag unusual stat patterns

### Collaboration
- **Coach Notes:** Add annotations to player stats
- **Player Feedback:** Allow players to view their own stats
- **Team Sharing:** Share dashboard with assistant coaches
- **Video Integration:** Link stats to video clips

---

## Questions for Stakeholder

1. **Priority Metrics:** Are there any specific metrics more important than others for your coaching workflow?
2. **Default Sort:** What should be the default sort order? (Total Points, Kills, Efficiency?)
3. **View Preference:** Do you prefer card view or table view as default for season dashboard?
4. **Non-Playing Players:** Should players who didn't play be:
   - Shown at bottom with 0s?
   - Hidden by default (toggle to show)?
   - Grayed out but in roster order?
5. **Thresholds:** Any minimum playing time/attempts before showing efficiency %? (e.g., don't show efficiency until 5+ attempts)
6. **Additional Stats:** Any other metrics you track manually that we should include?
7. **Export Format:** What format do you need for exporting stats? (PDF, CSV, Excel, printed?)
8. **Timeline:** When do you need this implemented by? Any upcoming tournament deadlines?

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Database Performance** | High | Medium | Implement materialized views, add indices, cache results |
| **UI Complexity** | Medium | Low | Iterative design with user testing, keep mobile-first |
| **Data Migration** | High | Low | Thorough testing, rollback plan, staged deployment |
| **User Confusion** | Medium | Medium | In-app tooltips, tutorial flow, documentation |
| **Scope Creep** | Medium | High | Strict MVP definition, defer enhancements to Phase 2 |

---

## Appendix

### A. File Structure
```
app/lib/features/history/
├── models/
│   ├── player_performance.dart (UPDATED)
│   ├── kpi_summary.dart
│   ├── match_summary.dart
│   └── set_summary.dart
├── widgets/
│   ├── player_performance_card_v2.dart (NEW)
│   ├── player_stats_table.dart (NEW)
│   ├── player_stats_controls.dart (NEW)
│   ├── player_performance_card.dart (LEGACY - keep for now)
│   └── ... (other existing widgets)
├── set_dashboard_screen.dart (REFACTOR)
├── match_recap_screen.dart (REFACTOR)
├── season_dashboard_screen.dart (REFACTOR)
└── providers.dart (UPDATED)

supabase/migrations/
├── 0005_player_stats_indices.sql (NEW)
└── 0006_materialized_views.sql (NEW - optional)
```

### B. Dependencies
No new Flutter packages required. Existing packages sufficient:
- `flutter_riverpod` - State management
- `supabase_flutter` - Database queries
- Current UI packages (already in use)

### C. Timeline Estimate
- **Phase 1 (Data Layer):** 3-4 days
- **Phase 2 (UI Components):** 4-5 days
- **Phase 3 (Screen Refactor):** 3-4 days
- **Phase 4 (Database):** 2-3 days
- **Phase 5 (Testing):** 3-4 days
- **Buffer:** 2-3 days

**Total Estimate:** 17-23 days (~3-4 weeks)

---

## Approval Sign-Off

- [ ] Requirements approved by Product Owner
- [ ] Design mockups approved by UX
- [ ] Technical approach approved by Tech Lead
- [ ] Timeline approved by Project Manager
- [ ] Ready to begin implementation

---

**End of Document**
