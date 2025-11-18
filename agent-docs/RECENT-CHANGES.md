# Recent Changes Summary

**Date:** January 2025  
**Focus:** Rally Capture UI Improvements & Stat Tracking Enhancements

## Overview

Recent work focused on completing the rally capture screen with comprehensive stat tracking capabilities, including substitution limits and attack efficiency calculations.

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

1. `app/lib/features/rally_capture/models/rally_models.dart`
   - Added `attackAttempt` enum value
   - Updated all extension switch statements

2. `app/lib/features/rally_capture/providers.dart`
   - Added substitution/timeout tracking to `RunningTotals`
   - Added `attackAttempts` to `PlayerStats`
   - Updated all stat calculation logic

3. `app/lib/features/rally_capture/rally_capture_screen.dart`
   - Added substitution counter display
   - Added substitution limit validation
   - Added Attack Attempt button to player grid
   - Updated player stats dialog with efficiency

4. `app/lib/features/rally_capture/data/rally_repository.dart`
   - Added `attackAttempt` handling in all mapping functions

5. `app/lib/features/export/csv_export_service.dart`
   - Added `attackAttempt` to CSV export calculations

---

## Next Steps

1. **Match Setup Wizard** - Discuss improvements to setup flow
2. **User Testing** - Test with coaches during practice matches
3. **Performance Testing** - Verify with large number of rallies
4. **Documentation** - Update user-facing documentation

---

## Known Issues

None currently identified. All linter errors resolved.

---

## Success Metrics

- ✅ Substitution limit tracking implemented and visible
- ✅ Substitutions don't block rally completion
- ✅ Attack attempts tracked and included in efficiency calculations
- ✅ All action types properly handled across codebase
- ✅ No linter errors
- ✅ All switch statements complete

