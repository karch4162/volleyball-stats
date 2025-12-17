# Rally Capture Feature

## Overview

The Rally Capture feature is the core of the volleyball stats app, providing coaches with a fast, intuitive interface to record rally outcomes and player actions during live matches.

## Status

✅ **Complete** (Phase 2 - December 2025)

Major UI/UX overhaul completed with comprehensive stat tracking capabilities.

## Key Features

### Scoreboard-First Layout
- Prominent score display at the top
- Running totals for FBK, Wins, Losses, Transition Points
- Collapsible score and timeout cards for space optimization
- Team name display

### Quick-Tap Player Actions
- Grid of player cards with action buttons
- One-tap action logging (no modals for common actions)
- Live stat counts on each button (kills, errors, attempts, blocks, etc.)
- Glass theme styling with shadow glow effects
- Real-time updates as actions are logged

### Rally Tracking
- One-tap Win/Loss rally buttons
- Auto-complete rally on FBK (First Ball Kill)
- Current rally summary widget
- Rally history view

### Statistics
- Per-player statistics breakdown
- Attack efficiency calculation: (Kills - Errors) / Total Attempts
- Kill percentage: Kills / Total Attempts
- Running totals provider tracks all stats in real-time

### Substitutions & Timeouts
- Substitution limit tracking (15 per set with remaining count)
- Substitution doesn't block rally completion
- Timeout tracking
- Compact rotation tracker

### User Experience
- Haptic feedback on actions
- Responsive layout optimized for mobile during live matches
- Consistent card widths and spacing
- Reduced data entry from 3-4 taps to 1 tap for most actions

## Documentation

- **[UI Plan](ui-plan.md)** - Original planning and design decisions
- **[UI Implementation](ui-implementation.md)** - Implementation details and technical notes

## Related

- **Architecture**: [ADR-001 Offline-First](../../adr/2025-12-16-offline-first.md), [ADR-002 Riverpod State](../../adr/2025-12-16-riverpod-state.md)
- **Status**: [Current Status](../../reports/status.md)
- **Recent Changes**: [Recent Changes Log](../../reports/recent-changes.md)

## Code Location

- `app/lib/features/rally_capture/rally_capture_screen.dart` - Main screen
- `app/lib/features/rally_capture/providers.dart` - State management
- `app/lib/features/rally_capture/models/` - Data models
- `app/lib/features/rally_capture/data/` - Repository layer

## Next Steps

Per [Current Status](../../reports/status.md):
- Comprehensive user testing
- Tablet/responsive layout optimizations (V2)
- Swipe gestures for undo/redo
- Local SQLite/Hive storage implementation
- Enhanced sync logic with Supabase

