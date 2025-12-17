# Recent Changes Summary

**Date:** January 2025  
**Focus:** Rally Capture UI Improvements & Stat Tracking Enhancements

## Overview

Recent work focused on completing the rally capture screen with comprehensive stat tracking capabilities, including substitution limits and attack efficiency calculations. Latest updates include UI refinements, player card redesign, and improved layout optimization.

---

## Latest Updates (Rally Capture UI Refinements) ✅

### 1. Player Action Buttons with Stat Counts ✅

**Problem:** Player action buttons didn't show current stat counts, requiring users to look elsewhere for statistics.

**Solution:**
- Added stat count display to each action button
- Counts appear next to icons using the same color as the icon
- Real-time updates as actions are logged
- Compact layout: icon + count on top, label below

**Files Modified:**
- `app/lib/features/rally_capture/rally_capture_screen.dart` - Updated `_ActionButton` widget

**Key Features:**
- Each button displays: Icon + Count (top row), Label (bottom)
- Count text uses button's accent color (indigo for Kill, rose for errors, etc.)
- Counts update live as actions are logged
- Removed redundant stat badges (K, A, B) from card header

**Button Mapping:**
- Kill → `stats.attackKills`
- Atk Err → `stats.attackErrors`
- Attempt → `stats.attackAttempts`
- Block → `stats.blocks`
- Dig → `stats.digs`
- Assist → `stats.assists`
- Ace → `stats.serveAces`
- Srv Err → `stats.serveErrors`
- FBK → `stats.fbk`

---

### 2. Glass Theme Button Styling ✅

**Problem:** Action buttons lacked visual depth and didn't match the glass morphism theme.

**Solution:**
- Applied glass background (`AppColors.glassLight`)
- Added border matching glass theme (`AppColors.borderMedium`)
- Implemented shadow glow effect with two shadows:
  - Colored glow using button's accent color (20% opacity)
  - Darker shadow for depth/raised effect
- Buttons now appear raised off the card

**Files Modified:**
- `app/lib/features/rally_capture/rally_capture_screen.dart` - Updated `_ActionButton` styling

**Visual Effects:**
- Glass background with subtle transparency
- Border matching overall theme
- Colored glow shadow (unique per button type)
- Depth shadow for raised appearance
- Material/InkWell for proper tap feedback

---

### 3. Collapsible Score & Timeout Cards ✅

**Problem:** Score card and timeout/substitution card took up too much vertical space, limiting visible players on screen.

**Solution:**
- Made both cards collapsible with expand/collapse headers
- Reduced padding and font sizes for more compact display
- Added visual indicators (expand/collapse icons)
- Both cards default to expanded state

**Files Modified:**
- `app/lib/features/rally_capture/rally_capture_screen.dart` - Converted `_RallyCaptureBody` to `ConsumerStatefulWidget`

**Key Features:**
- **Score Card:**
  - Header shows match info with expand/collapse icon
  - Collapsed: Shows only header row
  - Expanded: Shows team names, scores, and set number
  - Reduced padding (16px → 12px vertical)
  - Reduced font sizes (18→16 for names, 24→20 for scores)

- **Timeout/Substitution Card:**
  - Header shows "Timeouts & Substitutions" with expand/collapse icon
  - Collapsed: Shows only header row
  - Expanded: Shows timeout and substitution buttons
  - Reduced padding for compact display

**State Management:**
- `_scoreCardExpanded` - Controls score card visibility (default: true)
- `_timeoutSubCardExpanded` - Controls timeout/sub card visibility (default: true)

---

### 4. Team Name Display in Score Card ✅

**Problem:** Score card showed "Our Team" instead of the actual team name.

**Solution:**
- Integrated `selectedTeamProvider` to fetch current team
- Displays team name in score card
- Falls back to "Our Team" if no team selected

**Files Modified:**
- `app/lib/features/rally_capture/rally_capture_screen.dart` - Added team provider watch

**Implementation:**
- Uses `ref.watch(selectedTeamProvider)` to get current team
- Displays `selectedTeam?.name ?? 'Our Team'` in score card
- Team name appears on left side with team's score

---

### 5. Substitution Functionality Fixes ✅

**Problem:** Substituted-in players weren't appearing in the player list after substitution.

**Solution:**
- Updated `playerStatsProvider` to initialize stats for ALL roster players (not just active)
- Ensures any player can be substituted in and will have stats initialized
- Simplified logic by initializing all roster players upfront

**Files Modified:**
- `app/lib/features/rally_capture/providers.dart` - Updated `playerStatsProvider`

**Key Changes:**
- Initialize stats for all players in roster (active + bench)
- Any player can be substituted in and will appear immediately
- Players who don't play will have 0 stats (which is correct)
- Removed complex tracking of current lineup in stats provider

**Logic:**
```dart
// Initialize stats for ALL players on the team roster
final allRosterPlayers = <MatchPlayer>[];
allRosterPlayers.addAll(state.activePlayers);
allRosterPlayers.addAll(state.benchPlayers);
```

---

### 6. Layout & Spacing Improvements ✅

**Problem:** Player cards were overlapping with header, and cards had inconsistent widths.

**Solution:**
- Fixed Column layout with proper `crossAxisAlignment: CrossAxisAlignment.stretch`
- Removed animation wrapper that was constraining width
- Ensured all cards fill available width consistently
- Proper spacing between cards (8px)

**Files Modified:**
- `app/lib/features/rally_capture/rally_capture_screen.dart` - Fixed player card layout

**Layout Fixes:**
- Wrapped player cards in Column with `crossAxisAlignment.stretch`
- Removed `AnimatedSwitcher` wrapper (was causing width constraints)
- Cards now properly expand to full width
- Consistent spacing with other cards on screen

---

## Changes Completed

### 1. Substitution Limit Tracking ✅

**Problem:** Coaches need to track substitution limit (15 per set) to avoid exceeding the limit during matches.

**Solution:**
- Added substitution counter to `RunningTotals` class
- Displays "Subs Remaining" in running totals bar (starts at 15, decrements)
- Shows remaining count in substitution button: "Sub (15)", "Sub (14)", etc.
- Button disabled when limit reached (greyed out)
- Warning message if coach tries to substitute when limit reached
- Substitution dialog shows remaining count

**Files Modified:**
- `app/lib/features/rally_capture/providers.dart` - Added substitution tracking to `RunningTotals`
- `app/lib/features/rally_capture/rally_capture_screen.dart` - Added UI for substitution counter

**Key Features:**
- `RunningTotals.maxSubstitutionsPerSet = 15` (volleyball rule)
- `substitutionsRemaining` getter calculates remaining subs
- `canSubstitute` boolean for easy validation
- Visual feedback (purple when available, grey when limit reached)

---

### 2. Substitution Rally Completion Fix ✅

**Problem:** Substitutions were blocking rally completion, but substitutions often happen between rallies and shouldn't require a rally outcome.

**Solution:**
- Updated `canCompleteRally` logic in `RallyCaptureSession`
- Allows rally completion if only substitutions/timeouts are logged
- Substitutions and timeouts don't require point-scoring actions to complete rally

**Files Modified:**
- `app/lib/features/rally_capture/models/rally_models.dart` - Updated `canCompleteRally` logic

**Logic:**
```dart
// Rally can complete if:
// 1. Has point-scoring actions or errors, OR
// 2. Only has substitutions/timeouts (they happen between rallies)
```

---

### 3. Attack Attempt Tracking ✅

**Problem:** Need to track total attack attempts (not just kills/errors) to calculate attack efficiency ratio: (Kills - Errors) / Total Attempts

**Solution:**
- Added new `RallyActionTypes.attackAttempt` action type
- Tracks attacks that stay in play (neither kill nor error)
- Added to player quick-tap grid as "A" button
- Calculates total attacks = Kills + Errors + Attempts
- Calculates kill percentage = Kills / Total Attempts
- Calculates attack efficiency = (Kills - Errors) / Total Attempts

**Files Modified:**
- `app/lib/features/rally_capture/models/rally_models.dart` - Added `attackAttempt` enum and updated all switch statements
- `app/lib/features/rally_capture/providers.dart` - Added `attackAttempts` to `PlayerStats`, updated calculations
- `app/lib/features/rally_capture/rally_capture_screen.dart` - Added "A" button for Attack Attempt in player grid
- `app/lib/features/rally_capture/data/rally_repository.dart` - Added handling for attackAttempt in all mapping functions
- `app/lib/features/export/csv_export_service.dart` - Added attackAttempt to CSV export calculations

**Statistics Now Tracked:**
- **Attack Kills (K)** - Successful attacks that score points
- **Attack Errors (E)** - Attacks that result in errors
- **Attack Attempts (A)** - Attacks that stay in play
- **Total Attacks** - Sum of all three (K + E + A)
- **Kill Percentage** - Kills / Total Attempts * 100
- **Attack Efficiency** - (Kills - Errors) / Total Attempts * 100

**UI Updates:**
- Player Stats dialog shows: K, E, A, Total, Kill %, Efficiency
- Efficiency highlighted in primary color for visibility
- Attack Attempt button added to player quick-tap grid

---

## Technical Details

### Running Totals Enhancements

**New Fields:**
- `substitutions` - Total substitutions logged
- `timeouts` - Total timeouts logged
- `substitutionsRemaining` - Calculated remaining (15 - used)
- `canSubstitute` - Boolean for validation

**Display:**
- Running totals bar now has two rows:
  - Top: FBK, Wins, Losses, Transition Points
  - Bottom: Subs Remaining, Timeouts

### Player Stats Enhancements

**New Fields:**
- `attackAttempts` - Count of attack attempts (in play)
- `totalAttacks` - Calculated total (kills + errors + attempts)
- `attackPercentage` - Kill percentage (kills / total)
- `attackEfficiency` - Efficiency ratio ((kills - errors) / total)

### Action Type Updates

**New Action Type:**
- `RallyActionTypes.attackAttempt` - For attacks that stay in play

**Updated Switch Statements:**
- `isPlayerAction` - Returns `true` (player-specific action)
- `isPointScoring` - Returns `false` (doesn't score points)
- `isError` - Returns `false` (not an error)
- All repository mapping functions
- All CSV export functions

---

## Testing Recommendations

1. **Substitution Limit:**
   - Test substitution counter decrements correctly
   - Verify button disables at limit
   - Test that substitutions can be logged without blocking rally completion

2. **Attack Attempts:**
   - Verify attack attempts are counted in total attacks
   - Check efficiency calculations are correct
   - Verify CSV exports include attack attempts

3. **Rally Completion:**
   - Test rally completion with only substitutions
   - Test rally completion with only timeouts
   - Verify normal rally completion still works

---

## Files Modified

### Recent Updates (Latest Session)

1. `app/lib/features/rally_capture/rally_capture_screen.dart`
   - Redesigned `_ActionButton` with stat counts and glass styling
   - Converted `_RallyCaptureBody` to `ConsumerStatefulWidget` for expand/collapse state
   - Added collapsible score card and timeout/substitution card
   - Integrated team name display from `selectedTeamProvider`
   - Fixed player card layout and spacing
   - Removed redundant stat badges from card header

2. `app/lib/features/rally_capture/providers.dart`
   - Updated `playerStatsProvider` to initialize stats for all roster players
   - Simplified substitution handling logic

3. `app/lib/features/teams/team_providers.dart`
   - Added import for team provider access

### Previous Updates

1. `app/lib/features/rally_capture/models/rally_models.dart`
   - Added `attackAttempt` enum value
   - Updated all extension switch statements

2. `app/lib/features/rally_capture/providers.dart`
   - Added substitution/timeout tracking to `RunningTotals`
   - Added `attackAttempts` to `PlayerStats`
   - Updated all stat calculation logic

3. `app/lib/features/rally_capture/data/rally_repository.dart`
   - Added `attackAttempt` handling in all mapping functions

4. `app/lib/features/export/csv_export_service.dart`
   - Added `attackAttempt` to CSV export calculations

---

## Next Steps

1. **User Testing** - Comprehensive testing of rally capture functionality
   - Test all action buttons and stat tracking
   - Verify substitution functionality
   - Test expand/collapse cards
   - Verify team name display
   - Test with multiple players and substitutions
2. **Match Setup Wizard** - Discuss improvements to setup flow
3. **Performance Testing** - Verify with large number of rallies
4. **Documentation** - Update user-facing documentation

---

## Known Issues

None currently identified. All linter errors resolved.

---

## Success Metrics

### Latest Updates
- ✅ Player action buttons show real-time stat counts
- ✅ Glass theme styling with shadow glow effects
- ✅ Collapsible cards for better screen space usage
- ✅ Team name displayed correctly in score card
- ✅ Substitution functionality working correctly
- ✅ Improved layout and spacing consistency
- ✅ More players visible on screen

### Previous Updates
- ✅ Substitution limit tracking implemented and visible
- ✅ Substitutions don't block rally completion
- ✅ Attack attempts tracked and included in efficiency calculations
- ✅ All action types properly handled across codebase
- ✅ No linter errors
- ✅ All switch statements complete

