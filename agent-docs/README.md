# Agent Documentation Index

**Last Updated:** December 17, 2025

## Quick Navigation

- [Current Status](#current-status)
- [Active Work](#active-work)
- [Features](#features)
- [Reports](#reports)
- [Architecture Decisions](#architecture-decisions)
- [Guidelines](#guidelines)
- [Archive](#archive)

---

## Current Status

**Phase:** Phase 2 – Simplified Architecture & Local Storage + UI/UX Improvements + Stat Tracking

**Latest Update:** Rally Capture UI refinements and testing preparation complete. Major UI/UX overhaul with scoreboard-first layout, quick-tap player actions, and comprehensive stat tracking implemented. Ready for comprehensive user testing.

**See full status:** [reports/status.md](reports/status.md)

**Recent changes:** [reports/recent-changes.md](reports/recent-changes.md)

---

## Active Work

### Current Priorities
1. **Comprehensive user testing** - Test all functionality before next phase
2. **Match setup wizard improvements** - Discussion pending
3. **Local SQLite/Hive storage implementation** - Offline persistence

### Active Plans
- [Forward Plan](active/plans/forward-plan.md) - Overall development roadmap
- [Phase 11 Plan](active/todos/phase-11-plan.md) - Next phase work items

---

## Features

| Feature | Status | Documentation |
|---------|--------|---------------|
| **Rally Capture** | ✅ Complete (Phase 2) | [View](features/rally-capture/) |
| **Match Setup** | ✅ Complete (Phases 1-6) | [View](features/match-setup/) |
| **Dashboard** | ✅ Refactored | [View](features/dashboard/) |
| **Offline Sync** | ✅ Complete (Phase 1.1) | [View](features/offline-sync/) |
| **Authentication** | ✅ Complete (Phase 1.4) | [View](features/auth/) |

### Feature Details

- **[Rally Capture](features/rally-capture/)** - Scoreboard-first UI with quick-tap player actions, running totals, and comprehensive stat tracking
- **[Match Setup](features/match-setup/)** - Match configuration wizard with team selection, roster management, and templates
- **[Dashboard](features/dashboard/)** - Set, match, and season statistics views with player performance breakdowns
- **[Offline Sync](features/offline-sync/)** - Local-first data persistence with Hive, background sync, and conflict resolution
- **[Authentication](features/auth/)** - Offline-first auth with optional cloud sync, email verification, and cached credentials

---

## Reports

### Quality & Status
- **[Current Status](reports/status.md)** - Project status and next steps
- **[Recent Changes](reports/recent-changes.md)** - Latest updates and modifications
- **[QA Remediation Plan](reports/qa-remediation-plan.md)** - Comprehensive QA evaluation and fix roadmap
- **[Accessibility Checklist](reports/accessibility-checklist.md)** - Manual accessibility testing guide for QA

### Implementation Summaries
- **[Phase 1 Summary](reports/phase-summaries/phase-1-summary.md)** - Critical fixes: offline persistence, rotation tracking, match completion, offline auth
- **[Phase 3 Summary](reports/phase-summaries/phase-3-summary.md)** - Test coverage implementation: 60+ new tests for Phase 1 features
- **[Phase 4 Summary](reports/phase-summaries/phase-4-summary.md)** - Best practices: list keys, accessibility, error boundaries, performance
- **[Phase 7-9 Summary](reports/phase-summaries/phase-7-9-summary.md)** - Implementation summary for phases 7-9

---

## Architecture Decisions

Key technical decisions with rationale:

- **[ADR-001: Offline-First Architecture](adr/2025-12-16-offline-first.md)** - Why we chose offline-first Flutter approach
- **[ADR-002: Riverpod State Management](adr/2025-12-16-riverpod-state.md)** - State management decision
- **[ADR-003: Simplified Architecture](adr/2025-12-16-simplified-arch.md)** - No Node.js backend decision

[ADR Template](adr/template.md) - Use this template for new architecture decisions

---

## Guidelines

**[Repository Guidelines](guidelines.md)** - Coding standards, testing practices, commit conventions, and project structure

---

## Archive

Historical planning and reference documents:

- **[Development Plan](archive/development-plan.md)** - Original 6-phase development plan
- **[Simplified Development Plan](archive/simplified-dev-plan.md)** - Revised simplified approach
- **[Volleyball Stats Plan](archive/volleyball-stats-plan.md)** - Initial project concept
- **[Flutter Match Setup Plan](archive/flutter-match-setup-plan.md)** - Original Phase 1 match setup planning document
- **[RLS Policy Plan](archive/rls-policy-plan.md)** - Supabase row-level security policy planning
- **[Schema Notes](archive/schema-notes.md)** - Database schema design notes and rationale

---

## Navigation Tips

- **Looking for next steps?** → Check [Active Work](#active-work)
- **Feature-specific docs?** → See [Features](#features) table
- **Understand a decision?** → Review [Architecture Decisions](#architecture-decisions)
- **Latest updates?** → Check [Reports](#reports)
- **Historical context?** → Browse [Archive](#archive)

---

## Maintenance

When adding new documentation:
- **Architecture decisions** → Create new ADR in `adr/` using the template
- **Feature documentation** → Add to appropriate feature folder in `features/`
- **Status updates** → Update `reports/status.md` and `reports/recent-changes.md`
- **Completed plans** → Move to `archive/` when fully superseded
- **Update this index** → Keep the master navigation current

