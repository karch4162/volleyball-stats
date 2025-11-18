# Simplified Development Plan

## Architecture Overview

**New Simplified Stack:**
- **Flutter App** with local SQLite/Hive storage (offline-first)
- **Supabase** for cloud backup and multi-device sync (direct connection)
- **No Node.js Backend** - all processing done in Flutter

## Benefits
- Way less complexity and maintenance overhead
- Faster development and deployment
- Offline-first by design
- Easier testing and debugging
- More reliable with fewer points of failure

## Project Structure
```
volleyball-stats/
├── app/                          # Flutter client
│   ├── lib/
│   │   ├── core/                 # Shared constants and utilities
│   │   ├── storage/              # Local SQLite/Hive database
│   │   ├── sync/                 # Supabase sync logic
│   │   ├── features/             # Feature modules
│   │   │   ├── match_setup/
│   │   │   ├── rally_capture/
│   │   │   ├── history/
│   │   │   └── export/
│   │   └── main.dart
│   └── test/
├── supabase/                     # Database and cloud storage
│   ├── migrations/
│   ├── functions/
│   └── tests/
├── docs/                         # Documentation
├── agent-docs/                   # Development docs
└── ops/                          # CI/CD
```

## Revised Development Phases

### Phase 0: Simplified Foundation
1. Initialize git repo with AGENTS guidelines
2. Scaffold folder structure (remove `server/` directory)
3. Bootstrap Flutter project with local storage (SQLite/Hive)
4. Install and configure Supabase Flutter SDK
5. Set up CI for Flutter testing only

### Phase 1: Local Data & Storage
1. Implement local SQLite/Hive database models for matches, sets, rallies
2. Create repository pattern for local data access
3. Add basic CRUD operations for all entities
4. Implement offline-first data flow
5. Add local aggregation and reporting

### Phase 2: Supabase Integration (Optional)
1. Set up Supabase connection and authentication
2. Implement sync logic (local → Supabase, Supabase → local)
3. Handle conflict resolution for multi-device scenarios
4. Add backup/restore functionality

### Phase 3: Core Features
1. **Rally Capture**: Complete the stat input interface
2. **Match Management**: Setup flow and history
3. **Basic Analytics**: In-app stats and summaries
4. **Export Features**: Local CSV/PDF generation

### Phase 4: Polish & UI Simplification
1. Simplify rally capture UI (make it super fast to use)
2. Improve navigation and user flow
3. Add onboarding and help content
4. Performance optimization

### Phase 5: Testing & Release
1. Comprehensive testing (unit, widget, integration)
2. Test with real volleyball coaches
3. Beta release with feedback collection
4. Production release

## Key Technical Decisions

### Local Storage Strategy
- Primary: SQLite for relational data (matches, sets, rallies)
- Cache: Hive for app state and user preferences
- Supabase: Optional cloud backup and sync

### Sync Strategy (Simplified)
- Flutter app works fully offline
- Manual sync button for cloud backup
- Optional: Auto-sync when network available
- Simple conflict resolution (last write wins, with user notification)

### Export Strategy
- Local CSV generation (simple, universal)
- Local PDF generation using Flutter packages
- No server-side processing required

## What We're Removing
- ❌ Node.js backend with aggregation logic
- ❌ Complex queue-based sync system
- ❌ Server-side API endpoints
- ❌ Background job processing

## What We're Keeping or Adding
- ✅ Flutter app core functionality
- ✅ Supabase for cloud backup (optional but recommended)
- ✅ Local SQLite/Hive storage
- ✅ Simple sync logic
- ✅ In-app reporting and export
- ✅ Offline-first architecture

## Implementation Priority
1. **First**: Get rally capture working 100% offline
2. **Second**: Add local stats and export
3. **Third**: Add optional Supabase sync if time permits
4. **Fourth**: UI polish and optimization

This approach gets us to a working volleyball stats app much faster while maintaining the core features coaches need.
