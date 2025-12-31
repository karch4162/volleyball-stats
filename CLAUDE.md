# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mobile-first volleyball stat tracking app for coaches. Flutter client (Android/iOS/Web) with offline-first architecture and optional Supabase cloud sync.

**Key Design Decisions:**
- Offline-first: All data works locally with Hive; Supabase sync is optional
- No backend server: All processing done in Flutter locally (simplified architecture)
- Direct Supabase: Client connects directly with Row-Level Security (RLS)
- State management: Riverpod for type-safe, testable state

## Development Commands

```bash
# Install dependencies and run (from app/ directory)
cd app
flutter pub get
flutter run -d chrome|ios|android

# Run with Supabase credentials
flutter run -d chrome --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>

# Testing
flutter test                    # All tests
flutter test test/path/file.dart  # Single test file

# Analysis and builds
flutter analyze
flutter build apk|web|ios

# Code generation (after modifying freezed/json_serializable models)
dart run build_runner build --delete-conflicting-outputs

# Local Supabase (optional - app works fully offline)
supabase start
```

**Windows Note:** Run Flutter commands from Windows (PowerShell/Cursor), not WSL. The Windows Flutter SDK has CRLF scripts that fail under WSL.

## Architecture

```
app/lib/
├── main.dart              # Initialization (Hive first, then Supabase)
├── core/
│   ├── persistence/       # Hive service, type adapters
│   ├── providers/         # Riverpod providers
│   ├── router/            # GoRouter navigation
│   ├── sync/              # Offline sync logic
│   └── cache/             # Offline cache service
└── features/
    ├── auth/              # Login, signup, auth provider
    ├── match_setup/       # Wizard, templates, roster
    ├── rally_capture/     # Main stats entry screen
    ├── history/           # Dashboards, analytics
    ├── teams/             # Team management
    ├── players/           # Player management
    └── export/            # CSV/PDF generation

supabase/
├── migrations/            # SQL schema
├── seed.sql               # Test data
└── tests/                 # Integration tests
```

## Key Patterns

**Repositories:** Abstract interfaces with multiple implementations (Supabase, in-memory, cached). Falls back to in-memory if no Supabase credentials provided.

**Offline Persistence:** Match drafts persist in Hive, survive restarts, and sync to Supabase when available. CachedMatchSetupRepository wraps Supabase with local caching.

**Models:** Use Map-based serialization for Hive persistence. Freezed/json_serializable for code generation.

## Coding Conventions

- 2-space indentation, single quotes
- PascalCase widgets, camelCase providers, snake_case files
- Commit format: `type(scope): summary` (e.g., `feat(app): add serve rotation grid`)
- 80% minimum coverage on calculation modules
- SQL: lowercase table/column names

## Testing

- Widget tests for UI components
- Unit tests for models and calculations
- Integration tests require `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` environment variables (skipped otherwise)
- Accessibility tests for color contrast and semantics

## Additional Documentation

- `agent-docs/guidelines.md` - Detailed coding standards
- `agent-docs/adr/` - Architecture Decision Records
- `agent-docs/reports/` - Status and QA plans
