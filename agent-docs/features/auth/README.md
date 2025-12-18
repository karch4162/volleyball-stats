# Authentication Feature

**Status:** ✅ Complete (Phase 1.4)  
**Last Updated:** December 17, 2025

## Overview

The authentication feature provides flexible user authentication with full offline support. Users can choose to sign in for cloud sync or continue offline with full local functionality.

## Key Features

### Offline-First Authentication
- **Optional Authentication** - Users can bypass sign-in and use app offline
- **Credential Caching** - Auth state persisted in Hive for offline access
- **Anonymous Offline User** - Automatic creation of local user when offline
- **Auto-Sync** - Data automatically syncs when user comes back online

### Supabase Integration
- **Email/Password Auth** - Standard authentication flow
- **Email Verification** - Deep linking support for native apps
- **Session Management** - Persistent sessions with refresh tokens
- **RLS Support** - Row-level security for multi-user data

## Implementation Documents

- **[Offline Auth Implementation](offline-auth-implementation.md)** - Complete implementation details for Phase 1.4
- **[Email Verification Guide](email-verification-guide.md)** - Setup guide for email verification in Flutter

## Architecture

### Offline Mode Flow

```
User Launch → Check Network
    ↓
No Network → Offline Options Screen
    ↓
"Continue Offline" → Anonymous User Created
    ↓
Full App Access → Data saved locally
    ↓
Network Restored → Auto-sync queued data
```

### Authenticated Flow

```
User Launch → Network Available
    ↓
Not Signed In → Auth Screen
    ↓
Sign In/Sign Up → Supabase Auth
    ↓
Cache Credentials → Hive Storage
    ↓
Full App Access → Data syncs to cloud
```

## Key Components

### OfflineAuthState
Model for managing offline authentication state with cached credentials.

### OfflineAuthService
Service for persisting auth state to Hive and managing offline mode.

### AuthGuard
Widget that handles authentication checks and provides offline options.

## User Experience

### Available Offline
- ✅ Record match stats
- ✅ Local data storage
- ✅ View history and dashboards
- ✅ Auto-sync when online

### Requires Online
- ❌ Cloud backup/restore
- ❌ Team sharing
- ❌ Cross-device sync

## Testing

**Test Coverage:** Phase 1.4 implementation  
**Test File:** `test/features/auth/offline_auth_state_test.dart`

**Tests Include:**
- Offline auth state creation and serialization
- Anonymous user factory
- Cache validation logic
- Credential persistence

## Future Enhancements

- **Social Auth** - Google, Apple sign-in options
- **Multi-Device Detection** - Detect and handle conflicts
- **Team Sharing** - Share teams with assistant coaches
- **Advanced Sync** - Conflict resolution UI for manual handling

## Related Documentation

- [Offline Sync Feature](../offline-sync/README.md) - Local persistence and sync
- [Phase 1 Summary](../../reports/phase-summaries/phase-1-summary.md) - Overall Phase 1 implementation

