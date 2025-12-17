# Offline Sync Feature

## Overview

The Offline Sync feature ensures the app works seamlessly without internet connectivity, storing all data locally and synchronizing with Supabase when online.

## Status

🔄 **Planned** (Phase 1.1 - Not Started)

Critical feature for production readiness. Currently, the app has basic offline capabilities but lacks robust persistence and sync.

## Planned Features

### Local Persistence
- Hive/SQLite storage for matches, rallies, and actions
- Local-first repository layer
- Data persists across app restarts
- Encrypted local storage option

### Sync Queue
- Queue all changes for background sync
- Retry logic for failed syncs
- Batch sync operations
- Conflict detection and resolution

### Conflict Resolution
- Last-write-wins strategy (initial)
- Timestamp-based conflict detection
- User notifications for conflicts
- Manual resolution UI (future)

### Auth Flexibility
- "Sign in later" option
- App works fully without authentication
- Queue auth-required operations
- Cache auth state for offline access

## Architecture

See **[ADR-001: Offline-First Architecture](../../adr/2025-12-16-offline-first.md)** for detailed rationale.

## Implementation Plan

Per [QA Remediation Plan](../../reports/qa-remediation-plan.md) - Phase 1:

### Phase 1.1: Implement Offline Persistence
- Implement Hive box for matches, rallies, actions
- Create local-first repository layer
- Add sync queue with retry logic
- Implement conflict resolution
- Add tests for offline persistence and sync

### Phase 1.4: Fix Auth Guard for Offline
- Modify AuthGuard to allow offline usage
- Add "Sign in later" option
- Cache auth state for offline access
- Queue auth-required operations
- Add tests for offline auth flow

## Code Location

Planned locations:
- `app/lib/core/persistence/hive_service.dart` - Local storage service
- `app/lib/core/sync/sync_service.dart` - Sync orchestration
- `app/lib/core/sync/conflict_resolver.dart` - Conflict resolution
- `app/lib/features/*/data/*_local_repository.dart` - Local repositories

## Dependencies

- `hive` and `hive_flutter` - Local NoSQL database
- `sqflite` - SQLite database (alternative)
- `connectivity_plus` - Network status monitoring
- Supabase for cloud sync

## Success Criteria

1. ✅ App works fully offline (no degraded experience)
2. ✅ Data persists across app restarts
3. ✅ Automatic background sync when online
4. ✅ Conflict resolution handles concurrent edits
5. ✅ Users can delay authentication without losing functionality
6. ✅ Sync failures retry with exponential backoff
7. ✅ Clear UI indicators for sync status

## Related

- **Architecture**: [ADR-001 Offline-First](../../adr/2025-12-16-offline-first.md)
- **QA Report**: [QA Remediation Plan](../../reports/qa-remediation-plan.md) - Phase 1
- **Status**: [Current Status](../../reports/status.md) - Phase 2 next steps

