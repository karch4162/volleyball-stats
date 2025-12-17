# Match Setup Feature

## Overview

The Match Setup feature provides coaches with a wizard-style flow to configure matches before beginning rally capture, including team selection, roster management, opponent details, and match metadata.

## Status

✅ **Complete** (Phases 1-6)

Core match setup flow implemented with team management, roster templates, and match configuration.

## Key Features

### Match Setup Wizard
- Multi-step flow for match configuration
- Team selection (existing or create new)
- Opponent details input
- Match date, time, and location
- Set configuration

### Team Management
- Create and edit teams
- Team roster management
- Player details (name, jersey number, position)
- Roster templates for quick setup

### Templates
- Save roster configurations as templates
- Reuse templates for recurring lineups
- Template selection during match setup
- Quick match initialization

### Draft Management
- Auto-save match drafts
- Resume incomplete matches
- Draft validation before starting rally capture

## Documentation

- **[Improvement Plan](improvement-plan.md)** - Enhancement planning for match setup experience
- **[Phases 1-6 Summary](phases-1-6-summary.md)** - Completed work from phases 1-6

## Related

- **Architecture**: [ADR-003 Simplified Architecture](../../adr/2025-12-16-simplified-arch.md)
- **QA Report**: [QA Remediation Plan](../../reports/qa-remediation-plan.md) - Phase 1.3: Match Completion

## Code Location

- `app/lib/features/match_setup/` - Feature root
- `app/lib/features/match_setup/match_setup_flow.dart` - Main wizard
- `app/lib/features/match_setup/match_setup_landing_screen.dart` - Entry point
- `app/lib/features/match_setup/data/` - Repository layer
- `app/lib/features/match_setup/models/` - Data models

## Next Steps

Per [Improvement Plan](improvement-plan.md):
- Match setup wizard improvements (discussion pending)
- Enhanced template management
- Better roster validation
- Improved draft recovery flow

