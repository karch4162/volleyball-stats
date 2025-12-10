# Volleyball Stats App - Comprehensive QA Evaluation & Remediation Plan

## 📊 Executive Summary

**Overall Assessment:** The app has a solid foundation with good architectural patterns (Riverpod state management, repository pattern), but requires significant work in:
- **Code Quality**: 214 linter issues, deprecated APIs, no immutability patterns
- **Test Coverage**: Only 8 test files covering ~15% of codebase, no E2E tests
- **Best Practices**: Missing error boundaries, improper BuildContext usage, print() instead of logging
- **Missing Features**: Offline persistence (Hive/SQLite not implemented), rotation logic, match completion flow
- **Technical Debt**: TODOs scattered, inconsistent error handling, no proper logging framework

**Status**: The app is functional for basic online use but not production-ready for offline-first volleyball stat tracking.

---

## 🔍 DETAILED FINDINGS

### 1. CODE QUALITY ISSUES

#### A. Linter Issues (214 total)
- **prefer_const_constructors** (150+ violations): Missing const constructors across app
- **avoid_print** (40+ violations): Using print() instead of proper logging
- **deprecated_member_use** (15 violations): 
  - `ColorScheme.background` → should use `surface`
  - `ColorScheme.onBackground` → should use `onSurface`
  - `window.physicalSizeTestValue` → should use `WidgetTester.view`
- **unnecessary_brace_in_string_interps** (4 violations): `"${value}"` → `"$value"`
- **unused_import** (5 violations): Import cleanup needed
- **unnecessary_cast** (3 violations): Type inference issues
- **unused_local_variable** (2 violations): Dead code

**Files Most Affected:**
- `lib/core/theme/app_theme.dart` (15 issues)
- `lib/features/match_setup/data/offline_match_setup_repository.dart` (12 issues)
- `lib/features/match_setup/data/supabase_match_setup_repository.dart` (10 issues)

#### B. Architecture Issues

**No Immutability Patterns:**
- Models lack `@freezed` or `@immutable` annotations
- Mutable class fields everywhere (should be final)
- No code generation for models (json_serializable configured but not used)

**Files:**
```dart
// CURRENT (mutable, no validation)
class MatchPlayer {
  final String id;
  final String name;
  final int jerseyNumber;
  final String position;
}

// SHOULD BE (immutable with freezed)
@freezed
class MatchPlayer with _$MatchPlayer {
  const factory MatchPlayer({
    required String id,
    required String name,
    required int jerseyNumber,
    required String position,
  }) = _MatchPlayer;
  
  factory MatchPlayer.fromJson(Map<String, dynamic> json) => 
      _$MatchPlayerFromJson(json);
}
```

**BuildContext Usage in Async Functions:**
- 9 files with potential memory leaks (using BuildContext after await without checking mounted)
- Pattern: `Future<void> method(BuildContext context) async { await ...; Navigator.of(context)... }`

**Files:**
- `rally_capture_screen.dart` (3 instances)
- `match_setup_flow.dart` (6 instances)
- `match_recap_screen.dart` (1 instance)

**No Error Boundaries:**
- No ErrorWidget overrides at feature level
- Single global error handler in main.dart only
- Widget errors don't recover gracefully

**Inconsistent Repository Implementations:**
```dart
// SupabaseMatchSetupRepository: throws Exception
throw Exception('User must be authenticated...');

// OfflineMatchSetupRepository: returns empty/null
return [];

// No consistent error types across repositories
```

#### C. Missing Best Practices

**No Logging Framework:**
- Using print() statements (40+ instances)
- No log levels (debug, info, warning, error)
- No structured logging
- No ability to disable logs in production

**Should implement:**
```dart
// Use logger package
final logger = Logger('RallyCaptureScreen');
logger.i('Rally completed', rally.toJson());
logger.e('Failed to sync', error: e, stackTrace: st);
```

**No Keys for Dynamic Lists:**
- Player lists, rally lists lack unique keys
- Can cause incorrect widget reuse and state bugs
- Important for correct animations and rebuilds

**Missing Accessibility:**
- No semantic labels on buttons/images
- No screen reader support
- Missing tooltips on icon-only buttons
- Color contrast not verified

---

### 2. TEST COVERAGE GAPS

#### Current Coverage: ~15% (8 test files)

**Existing Tests:**
1. ✅ `app_test.dart` - Placeholder only
2. ✅ `rally_capture_screen_test.dart` - 1 widget test
3. ✅ `match_setup_flow_test.dart` - 3 widget tests
4. ✅ `integration/match_setup_repository_test.dart` - 1 integration test
5. ✅ `features/rally_capture/rally_capture_session_controller_test.dart` - Unit tests
6. ✅ `features/history/models/player_performance_test.dart` - 18 unit tests
7. ✅ `features/history/widgets/player_performance_card_v2_test.dart` - 12 widget tests
8. ✅ `features/history/widgets/player_stats_controls_test.dart` - 11 widget tests

**Test Results:** 
- ✅ All 53 tests passing
- ❌ Only covers ~15% of codebase

#### Missing Test Coverage:

**A. Screen Tests (0/10 screens tested)**
- ❌ HomeScreen
- ❌ MatchSetupLandingScreen
- ❌ TeamListScreen, TeamCreateScreen, TeamEditScreen
- ❌ PlayerListScreen, PlayerCreateScreen, PlayerEditScreen
- ❌ SetDashboardScreen ⚠️ CRITICAL - Has complex sorting/filtering logic
- ❌ MatchRecapScreen ⚠️ CRITICAL - Aggregates match stats
- ❌ SeasonDashboardScreen
- ❌ MatchHistoryScreen
- ❌ ExportScreen
- ❌ LoginScreen, SignupScreen

**B. Business Logic Tests (Missing)**
- ❌ Analytics calculator (complex calculations)
- ❌ Running totals provider (FBK, wins, losses tracking)
- ❌ Player stats provider (attack efficiency, service pressure)
- ❌ Export CSV service (data formatting)
- ❌ Rally sync logic (offline queue, retry)
- ❌ Substitution limits (15 per set validation)
- ❌ Rotation logic (TODO - not implemented yet)

**C. Repository Tests (1/7)**
- ✅ MatchSetupRepository (in-memory only)
- ❌ SupabaseMatchSetupRepository (integration)
- ❌ OfflineMatchSetupRepository
- ❌ CachedMatchSetupRepository
- ❌ RallySyncRepository
- ❌ AuthService
- ❌ ExportService

**D. Error Scenarios (0 tests)**
- ❌ Network failures
- ❌ Auth failures
- ❌ Supabase connection errors
- ❌ Offline data persistence
- ❌ Sync conflicts
- ❌ Invalid data handling

**E. E2E/Integration Tests (0)**
- ❌ Complete match flow (setup → capture → review)
- ❌ Offline→Online sync flow
- ❌ Multi-set match completion
- ❌ Team/Player CRUD operations
- ❌ Template creation and reuse
- ❌ Export workflow

---

### 3. BROKEN/INCOMPLETE FUNCTIONALITY

#### A. TODOs in Production Code (8 locations)

```dart
// CRITICAL MISSING FEATURES:

1. rally_capture_screen.dart:191
   // TODO: Mark match as completed in database
   ⚠️ No actual match completion logic

2. rally_capture_screen.dart:505
   // TODO: Implement rotation logic
   ⚠️ Rotation tracking completely missing

3. providers.dart:284
   rotation: 1, // TODO: Get current rotation from UI state
   ⚠️ Hardcoded rotation (breaks stat tracking)

4. offline_match_setup_repository.dart:168
   // TODO: Save to local storage when implementing offline capability
   ⚠️ Claims offline-first but no persistence

// MEDIUM PRIORITY:

5. team_selection_screen.dart:127
   // TODO: Navigate to team creation screen
   
6. match_recap_screen.dart:192
   // TODO: Implement match-specific export

7. export_screen.dart:81
   // TODO: Add match summary option

8. login_screen.dart:201
   // TODO: Navigate to password reset screen
```

#### B. Missing Core Features

**1. Offline Persistence (CRITICAL)**
- ❌ Hive configured in pubspec.yaml but NOT USED
- ❌ SQLite (sqflite) configured but NOT USED
- ❌ No local database implementation
- ❌ All data only stored in-memory (lost on app restart)
- ❌ "Offline-first" claim in docs is FALSE

**Impact:** Users lose all match data if app crashes or restarts while offline.

**2. Rotation Logic (CRITICAL)**
- ❌ Rotation tracking hardcoded to 1
- ❌ No rotation advancement on serve changes
- ❌ Can't track which rotation scored points
- ❌ Breaks per-rotation statistics mentioned in AGENTS.md

**Impact:** Cannot analyze team performance by rotation as intended.

**3. Match Completion Flow (HIGH)**
- ❌ End Match button shows dialog but doesn't save
- ❌ No final score persistence
- ❌ No match status field (in-progress vs completed)
- ❌ Can't filter completed matches in history

**Impact:** No way to mark matches as complete; history shows all matches as ongoing.

**4. Sync Conflict Resolution (HIGH)**
- ❌ No conflict detection when syncing offline changes
- ❌ Last-write-wins (overwrites server data)
- ❌ No merge strategies for concurrent edits

**Impact:** Data loss if multiple devices edit same match offline.

**5. Password Reset Flow (MEDIUM)**
- ❌ Forgot Password link does nothing
- ❌ No password reset screen
- ❌ Users can't recover locked accounts

#### C. Inconsistent Implementation

**Auth Guard Blocks Offline Use:**
```dart
// AuthGuard prevents using app offline
if (!supabaseConnected) {
  return Scaffold(body: Text('Supabase Not Connected'));
}
```
**Problem:** Contradicts "offline-first" architecture claim. App should work offline but requires Supabase connection to start.

**Repository Inconsistencies:**
- `SupabaseMatchSetupRepository.supportsEntityCreation = true`
- `OfflineMatchSetupRepository.supportsEntityCreation = false`
- But both implement same interface with same methods!
- Methods throw exceptions instead of returning consistent error types

---

### 4. FLUTTER BEST PRACTICES VIOLATIONS

#### A. State Management Issues

**1. StatefulWidget Overuse:**
```dart
// 14 StatefulWidgets vs 5 ConsumerStatefulWidgets
// Many don't need to be stateful at all

class _StatChip extends StatelessWidget {
  // Should be const constructor
  const _StatChip(this.label, this.value);
}
```

**2. Missing Keys in Lists:**
```dart
// rally_capture_screen.dart - Recent Rallies list
return Column(
  children: sortedPlayers.map((player) => 
    PlayerCard(performance: player) // ❌ Missing key
  ).toList(),
);

// SHOULD BE:
return Column(
  children: sortedPlayers.map((player) => 
    PlayerCard(
      key: ValueKey(player.playerId),
      performance: player,
    )
  ).toList(),
);
```

**3. BuildContext After Async:**
```dart
// match_setup_flow.dart:227 (and 8 other places)
Future<void> _pickMatchDate(BuildContext context) async {
  final date = await showDatePicker(context: context, ...);
  if (date != null) {
    setState(() { _matchDate = date; }); // ⚠️ No mounted check
  }
}

// SHOULD BE:
Future<void> _pickMatchDate(BuildContext context) async {
  final date = await showDatePicker(context: context, ...);
  if (date != null && mounted) {
    setState(() { _matchDate = date; });
  }
}
```

#### B. Performance Issues

**1. Rebuilding Entire Trees:**
- No const constructors = unnecessary rebuilds
- Missing memo/select patterns in providers
- Every text change triggers full tree rebuild

**2. Expensive Operations in Build:**
```dart
// set_dashboard_screen.dart
Widget build(BuildContext context) {
  final sortedPlayers = _sortPlayers(players, _sortBy); // ❌ Sorts on every build
  
  // Should use memoization or move to provider
}
```

#### C. Navigation Issues

**1. No Named Routes:**
- All navigation uses imperative `Navigator.push()`
- Hard to test navigation
- No deep linking support
- go_router configured but barely used

**2. Memory Leaks:**
```dart
// Controllers not disposed in 6 screens
class TeamCreateScreen extends ConsumerStatefulWidget {
  final _nameController = TextEditingController(); // ❌ Never disposed
}
```

---

### 5. SECURITY & DATA INTEGRITY

#### A. RLS Policies

**Status:** ✅ Properly configured
- Migration 0002 sets up RLS policies
- Migration 0004 ensures RLS enabled
- Tables protected by coach_id checks

#### B. Data Validation

**Missing Validation:**
```dart
// No input validation in models
class MatchPlayer {
  final int jerseyNumber; // ❌ No range check (1-99?)
  final String position;  // ❌ No enum/validation (S, OH, MB, etc?)
}

// Should validate:
// - Jersey numbers: 1-99
// - Positions: Must be valid volleyball position
// - Names: Non-empty, max length
// - Dates: Not in future for completed matches
```

#### C. Error Messages Expose Internal Details

```dart
// Showing database errors to users
catch (error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString())), // ❌ Raw error
  );
}

// Should sanitize:
'Failed to save draft: 
PostgresException: duplicate key violates unique constraint...'
→ 'Unable to save. Please try again.'
```

---

## 📋 REMEDIATION PLAN

### PHASE 1: CRITICAL FIXES (Blocker Issues)
**Priority:** P0 - Must Fix Before Production
**Timeline:** 2-3 weeks

#### 1.1 Implement Offline Persistence
**Tasks:**
- [ ] Implement Hive box for matches, rallies, actions
- [ ] Create local-first repository layer
- [ ] Add sync queue with retry logic
- [ ] Implement conflict resolution (last-write-wins initially)
- [ ] Add unit tests for offline persistence
- [ ] Add integration tests for offline→online sync

**Files to Create:**
- `lib/core/persistence/hive_service.dart`
- `lib/features/rally_capture/data/rally_local_repository.dart`
- `lib/core/sync/sync_service.dart`
- `lib/core/sync/conflict_resolver.dart`

**Files to Modify:**
- `lib/features/match_setup/data/offline_match_setup_repository.dart`
- `lib/features/rally_capture/providers.dart`

**Tests Required:**
- Offline data persistence (save/load/delete)
- Sync queue management
- Conflict resolution scenarios
- App restart data recovery

#### 1.2 Fix Rotation Tracking
**Tasks:**
- [ ] Add rotation state to `RallyCaptureSession`
- [ ] Implement rotation advancement on serve changes
- [ ] Add rotation picker UI
- [ ] Store rotation per rally in database
- [ ] Update queries to aggregate by rotation
- [ ] Add unit tests for rotation logic
- [ ] Add widget tests for rotation UI

**Files to Modify:**
- `lib/features/rally_capture/models/rally_models.dart`
- `lib/features/rally_capture/providers.dart`
- `lib/features/rally_capture/rally_capture_screen.dart`
- Database migrations (add rotation_number to rallies table)

**Tests Required:**
- Rotation advancement logic
- Rotation display/selection UI
- Per-rotation stat calculations

#### 1.3 Implement Match Completion
**Tasks:**
- [ ] Add match status enum (in-progress, completed, cancelled)
- [ ] Implement End Match flow (save final score, timestamp)
- [ ] Add match completion database field
- [ ] Update history filters to show completed matches
- [ ] Add ability to resume incomplete matches
- [ ] Add tests for match completion flow

**Files to Modify:**
- Database migration (add status, completed_at to matches)
- `lib/features/rally_capture/rally_capture_screen.dart`
- `lib/features/match_setup/models/match_draft.dart`
- `lib/features/history/match_history_screen.dart`

**Tests Required:**
- Match completion saves correctly
- Filter completed vs in-progress matches
- Can resume incomplete matches

#### 1.4 Fix Auth Guard for Offline
**Tasks:**
- [ ] Modify AuthGuard to allow offline usage
- [ ] Add "Sign in later" option
- [ ] Cache auth state for offline access
- [ ] Queue auth-required operations for later
- [ ] Add tests for offline auth flow

**Files to Modify:**
- `lib/features/auth/auth_guard.dart`
- `lib/features/auth/auth_provider.dart`

---

### PHASE 2: CODE QUALITY (Technical Debt)
**Priority:** P1 - Should Fix Soon
**Timeline:** 2 weeks

#### 2.1 Resolve Linter Issues
**Tasks:**
- [ ] Add const constructors (150+ locations)
- [ ] Replace deprecated APIs:
  - `ColorScheme.background` → `surface`
  - `ColorScheme.onBackground` → `onSurface`
  - `window.*` → `WidgetTester.view.*`
- [ ] Remove unnecessary braces in string interpolation
- [ ] Clean up unused imports
- [ ] Remove unnecessary casts
- [ ] Remove unused variables

**Automation:**
```bash
# Auto-fix many issues
dart fix --apply
flutter pub run import_sorter:main
```

**Verify:**
```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
# Target: 0 issues
```

#### 2.2 Replace print() with Logging
**Tasks:**
- [ ] Add logger package
- [ ] Create logger instances per feature
- [ ] Replace all print() calls (40+ instances)
- [ ] Add log levels (debug, info, warning, error)
- [ ] Configure logging in production (disable debug)

**Example:**
```dart
// Add to pubspec.yaml
dependencies:
  logger: ^2.0.0

// Create logger
final logger = Logger(
  printer: PrettyPrinter(methodCount: 0),
  level: kDebugMode ? Level.debug : Level.warning,
);

// Replace print()
// OLD: print('Saving draft: $matchId');
// NEW: logger.i('Saving draft', error: matchId);
```

#### 2.3 Add Immutability with Freezed
**Tasks:**
- [ ] Generate freezed models for all data classes
- [ ] Add @freezed annotations
- [ ] Run build_runner
- [ ] Update all copyWith() usages
- [ ] Add JSON serialization

**Priority Models:**
- `MatchPlayer`
- `MatchDraft`
- `RosterTemplate`
- `PlayerPerformance`
- `RallyEvent`
- `RallyRecord`

**Example:**
```dart
@freezed
class MatchPlayer with _$MatchPlayer {
  const factory MatchPlayer({
    required String id,
    required String name,
    @Assert('jerseyNumber > 0 && jerseyNumber < 100')
    required int jerseyNumber,
    required String position,
  }) = _MatchPlayer;
  
  factory MatchPlayer.fromJson(Map<String, dynamic> json) =>
      _$MatchPlayerFromJson(json);
}
```

#### 2.4 Fix BuildContext Async Issues
**Tasks:**
- [ ] Add mounted checks after all awaits (9 files)
- [ ] Use BuildContext extensions for safer access
- [ ] Add linter rule to catch violations

**Pattern:**
```dart
// Before
Future<void> _submit(BuildContext context) async {
  await repository.save(data);
  Navigator.of(context).pop();
}

// After
Future<void> _submit(BuildContext context) async {
  await repository.save(data);
  if (!mounted) return;
  if (context.mounted) {
    Navigator.of(context).pop();
  }
}
```

---

### PHASE 3: TEST COVERAGE (Quality Assurance)
**Priority:** P1 - Should Fix Soon  
**Timeline:** 3 weeks

#### 3.1 Screen Widget Tests
**Tasks:**
- [ ] Test all 10 main screens
- [ ] Test happy path rendering
- [ ] Test error states
- [ ] Test loading states
- [ ] Test interactions (buttons, forms)

**Target Files:**
- `test/features/match_setup/home_screen_test.dart`
- `test/features/match_setup/match_setup_landing_screen_test.dart`
- `test/features/history/set_dashboard_screen_test.dart` ⚠️ HIGH PRIORITY
- `test/features/history/match_recap_screen_test.dart` ⚠️ HIGH PRIORITY
- `test/features/history/season_dashboard_screen_test.dart`
- `test/features/history/match_history_screen_test.dart`
- `test/features/teams/team_list_screen_test.dart`
- `test/features/players/player_list_screen_test.dart`
- `test/features/export/export_screen_test.dart`
- `test/features/auth/login_screen_test.dart`

**Test Template:**
```dart
testWidgets('Screen displays correctly with data', (tester) async {
  await tester.pumpWidget(createTestApp(child: Screen()));
  await tester.pumpAndSettle();
  
  expect(find.text('Expected Title'), findsOneWidget);
  expect(find.byType(LoadingIndicator), findsNothing);
});

testWidgets('Screen shows error state', (tester) async {
  // Mock error
  await tester.pumpWidget(createTestApp(
    overrides: [provider.overrideWith((ref) => throw 'Error')],
    child: Screen(),
  ));
  await tester.pumpAndSettle();
  
  expect(find.text('Error message'), findsOneWidget);
  expect(find.byType(RetryButton), findsOneWidget);
});
```

#### 3.2 Business Logic Unit Tests
**Tasks:**
- [ ] Test analytics calculator (complex formulas)
- [ ] Test running totals calculations
- [ ] Test player stats calculations
- [ ] Test export CSV formatting
- [ ] Test rally sync queue logic
- [ ] Test substitution limits validation

**Files to Create:**
- `test/features/history/utils/analytics_calculator_test.dart`
- `test/features/rally_capture/providers_test.dart` (totals, stats)
- `test/features/export/csv_export_service_test.dart`
- `test/features/rally_capture/data/rally_sync_repository_test.dart`

**Coverage Target:** 80%+ on business logic

#### 3.3 Repository Integration Tests
**Tasks:**
- [ ] Test all repository implementations
- [ ] Test with real Supabase (test project)
- [ ] Test offline fallback logic
- [ ] Test cache invalidation
- [ ] Test error handling

**Files to Create:**
- `test/integration/supabase_match_setup_repository_test.dart`
- `test/integration/offline_match_setup_repository_test.dart`
- `test/integration/cached_match_setup_repository_test.dart`
- `test/integration/rally_sync_repository_test.dart`
- `test/integration/auth_service_test.dart`

**Setup:**
```dart
// test/integration/setup.dart
Future<SupabaseClient> createTestSupabaseClient() async {
  await Supabase.initialize(
    url: Platform.environment['TEST_SUPABASE_URL']!,
    anonKey: Platform.environment['TEST_SUPABASE_ANON_KEY']!,
  );
  return Supabase.instance.client;
}
```

#### 3.4 Error Scenario Tests
**Tasks:**
- [ ] Test network failure handling
- [ ] Test auth token expiration
- [ ] Test Supabase RLS errors
- [ ] Test offline data recovery
- [ ] Test sync conflicts
- [ ] Test invalid input validation

**Example:**
```dart
test('Repository handles network failure gracefully', () async {
  // Mock network error
  when(client.from('matches').select())
    .thenThrow(SocketException('Network unreachable'));
  
  final result = await repository.fetchMatches();
  
  expect(result.isError, true);
  expect(result.error, isA<NetworkException>());
});
```

#### 3.5 E2E Integration Tests
**Tasks:**
- [ ] Test complete match flow (setup → capture → review)
- [ ] Test offline → online sync flow
- [ ] Test team/player CRUD operations
- [ ] Test template creation and reuse
- [ ] Test export workflow

**Files to Create:**
- `integration_test/match_flow_test.dart`
- `integration_test/offline_sync_test.dart`
- `integration_test/team_management_test.dart`
- `integration_test/export_test.dart`

**Run E2E:**
```bash
flutter test integration_test/
flutter drive --driver=test_driver/integration_test.dart \
              --target=integration_test/match_flow_test.dart
```

**Target:** Full user journeys passing

---

### PHASE 4: BEST PRACTICES (Polish)
**Priority:** P2 - Nice to Have
**Timeline:** 1-2 weeks

#### 4.1 Add List Keys
**Tasks:**
- [ ] Add ValueKey/ObjectKey to all dynamic lists
- [ ] Player lists
- [ ] Rally lists
- [ ] Set/Match history lists

#### 4.2 Add Accessibility
**Tasks:**
- [ ] Add Semantics widgets
- [ ] Add tooltips to icon-only buttons
- [ ] Verify color contrast ratios
- [ ] Test with screen reader (TalkBack/VoiceOver)

#### 4.3 Implement Named Routes
**Tasks:**
- [ ] Define routes in go_router
- [ ] Replace Navigator.push() with context.go()
- [ ] Add deep linking support
- [ ] Test navigation

#### 4.4 Add Error Boundaries
**Tasks:**
- [ ] Create feature-level ErrorWidget builders
- [ ] Add retry mechanisms
- [ ] Improve error messages for users

#### 4.5 Performance Optimization
**Tasks:**
- [ ] Add const constructors everywhere
- [ ] Memoize expensive computations
- [ ] Add provider selectors to reduce rebuilds
- [ ] Profile and optimize hot paths

---

### PHASE 5: MISSING FEATURES (Enhancement)
**Priority:** P2-P3 - Future Work
**Timeline:** 2-3 weeks

#### 5.1 Password Reset Flow
- [ ] Create password reset screen
- [ ] Implement Supabase password reset
- [ ] Handle deep links from email
- [ ] Test recovery flow

#### 5.2 Match-Specific Export
- [ ] Implement single match export (PDF)
- [ ] Add match summary page
- [ ] Custom export options

#### 5.3 Advanced Filters
- [ ] Season dashboard date range improvements
- [ ] Filter by player
- [ ] Filter by opponent
- [ ] Save filter presets

---

## 📊 TESTING STRATEGY

### Test Pyramid Target

```
        /\
       /  \  E2E (5 tests - 5%)
      /____\
     /      \  Integration (25 tests - 25%)
    /________\
   /          \  Unit (70 tests - 70%)
  /__Widget___\
```

**Current:** 53 tests (15% coverage)  
**Target:** 200+ tests (80%+ coverage)

### Test Checklist by Feature

#### Rally Capture
- [x] RallyCaptureSessionController unit tests
- [x] RallyCaptureScreen basic widget test
- [ ] Player stats calculations
- [ ] Running totals calculations
- [ ] Substitution limits
- [ ] Rally completion validation
- [ ] Offline persistence
- [ ] Sync queue management
- [ ] Error handling
- [ ] E2E: Complete match recording

#### Match Setup
- [x] MatchSetupFlow widget tests (3)
- [x] MatchSetupRepository integration test
- [ ] Template management
- [ ] Draft auto-save
- [ ] Rotation validation
- [ ] Team selection
- [ ] Error recovery
- [ ] E2E: Match setup to capture

#### History/Dashboard
- [x] PlayerPerformance model tests (18)
- [x] PlayerPerformanceCardV2 widget tests (12)
- [x] PlayerStatsControls widget tests (11)
- [ ] SetDashboardScreen widget test ⚠️ CRITICAL
- [ ] MatchRecapScreen widget test ⚠️ CRITICAL
- [ ] SeasonDashboardScreen widget test
- [ ] Analytics calculator unit tests
- [ ] Sorting/filtering logic
- [ ] E2E: Review and export stats

#### Teams/Players
- [ ] Team CRUD operations
- [ ] Player CRUD operations
- [ ] Team selection
- [ ] Validation logic
- [ ] RLS policy enforcement
- [ ] E2E: Team management flow

#### Export
- [ ] CSV generation
- [ ] Data formatting
- [ ] File save/share
- [ ] Error handling
- [ ] E2E: Export workflow

---

## 🎯 SUCCESS METRICS

### Code Quality
- [ ] 0 linter errors (currently 214)
- [ ] 0 linter warnings
- [ ] 0 print() statements (use logger)
- [ ] All models use freezed
- [ ] All controllers properly disposed

### Test Coverage
- [ ] 80%+ line coverage
- [ ] 90%+ on business logic
- [ ] All screens have widget tests
- [ ] 25+ integration tests
- [ ] 5+ E2E tests

### Functionality
- [ ] Offline persistence working
- [ ] Rotation tracking implemented
- [ ] Match completion flow complete
- [ ] Sync with conflict resolution
- [ ] Auth works offline

### Performance
- [ ] Flutter analyze passes with 0 issues
- [ ] All tests pass in < 2 minutes
- [ ] App launches in < 2 seconds
- [ ] Dashboards load in < 3 seconds

---

## 💰 ESTIMATED EFFORT

| Phase | Tasks | Priority | Estimate |
|-------|-------|----------|----------|
| Phase 1: Critical Fixes | 4 major features | P0 | 2-3 weeks |
| Phase 2: Code Quality | 4 cleanup efforts | P1 | 2 weeks |
| Phase 3: Test Coverage | 5 test suites | P1 | 3 weeks |
| Phase 4: Best Practices | 5 polish tasks | P2 | 1-2 weeks |
| Phase 5: Missing Features | 3 new features | P2-P3 | 2-3 weeks |
| **TOTAL** | | | **10-13 weeks** |

**Note:** Assumes 1 developer working full-time. Can be parallelized with multiple developers.

---

## 🚨 RISK ASSESSMENT

### High Risk
- **Offline persistence**: Core architectural change affecting all data flow
- **Rotation logic**: Impacts all stat tracking and historical analysis
- **Database migrations**: Risk of data loss if not carefully planned

### Medium Risk
- **Freezed migration**: Many breaking changes across codebase
- **Test coverage**: Time-consuming but low technical risk
- **BuildContext fixes**: Tedious but straightforward

### Low Risk
- **Linter fixes**: Mostly automated
- **Logging**: Simple find-and-replace
- **Accessibility**: Additive, no breaking changes

---

## 📝 NEXT STEPS

1. **Review this plan** with stakeholders
2. **Prioritize** phases based on business needs
3. **Set up test infrastructure** (test Supabase project, CI/CD)
4. **Start Phase 1** (Critical Fixes) with offline persistence
5. **Continuous integration** with Phase 2 (Code Quality) tasks
6. **Parallel track** for Phase 3 (Test Coverage)

---

## ❓ QUESTIONS FOR STAKEHOLDER

1. **Offline Priority**: How critical is offline-first? Can we ship with online-only initially?
2. **Rotation Tracking**: Is per-rotation analysis essential for MVP?
3. **Test Coverage**: What's acceptable coverage for initial release? (Recommend 70%+)
4. **Timeline**: Do we have 10-13 weeks for remediation or need to scope down?
5. **Technical Debt**: Should we fix P2 issues (best practices) or add new features instead?

---

**Document Generated:** 2025-12-10  
**Analysis Tool:** Flutter Context7 + Manual Code Review  
**Test Results:** 53/53 passing, 214 linter issues identified  
**Codebase Version:** commit b73a898 (main branch)

---

**END OF EVALUATION**
