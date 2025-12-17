# Match Setup Improvement - Phases 1-10 Summary

> **Status:** Phases 1-6 Complete ✅ | Phases 7-10 Planned 📋
> 
> This document tracks the match setup feature implementation, including completed work (Phases 1-6) and the planned architecture improvements (Phases 7-10) for authentication, multi-tenancy, and proper offline handling.

## Completed Work

### Phase 1-2: Foundation & Landing Screen ✅
- Created `RosterTemplate` model (roster + rotation only, no match metadata)
- Extended `MatchSetupRepository` interface with template methods
- Implemented template persistence across all repository types (in-memory, Supabase, cached, offline)
- Built `MatchSetupLandingScreen` with quick start options (Use Last Match, Use Template, Start Fresh)

### Phase 3: Template Management UI ✅
- `TemplateListScreen` - View, delete templates with usage stats
- `TemplateEditScreen` - Create/edit templates with player selection and rotation assignment
- "Save as Template" button in match setup flow
- Template picker modal for quick selection

### Phase 4-5: Streamlined Single-Screen Setup ✅
- Replaced 4-step stepper with single scrollable screen
- Created `RotationGrid` component - visual 3x2 grid for rotation assignment
- Added completion indicators and progress counters
- Integrated quick actions (template/clone) into main flow

### Phase 6: Auto-Save Functionality ✅
- Debounced auto-save (2s delay after changes)
- Saves to both Hive cache (local) and Supabase (cloud)
- Visual indicators in AppBar (spinner/checkmark/error icon)
- Auto-save triggers on: text changes, date picker, player selection, rotation changes

## Current Issues

### Issue 1: Templates Not Saving to Supabase
**Symptoms:**
- Template creation closes window with no error
- `roster_templates` table remains empty
- No console errors visible

**Root Causes Identified:**
1. **RLS Policies** - Removed for now (auth not implemented)
2. **Player ID Mismatch** - Hardcoded player IDs (`'player-avery'`) don't match database UUIDs (`'21111111-1111-1111-1111-111111111111'`)
3. **Repository Fallback** - If Supabase not connected, uses `InMemoryMatchSetupRepository` with hardcoded players

**Debugging Added:**
- Enhanced logging in `saveRosterTemplate` to show:
  - Which repository is active (Supabase vs In-Memory)
  - Player ID validation (checks if IDs exist in database)
  - Full payload and error details
- Error handling in `TemplateEditScreen` (shows error snackbar, doesn't close on error)

### Issue 2: Player Count Mismatch
**Symptoms:**
- Database has 3 players
- UI shows 7 players

**Root Cause:**
- `InMemoryMatchSetupRepository` has 7 hardcoded players used when Supabase not connected
- If Supabase IS connected but only 3 players in DB, should show 3
- Check console logs to see which repository is active

**Team Concept:**
- Teams enable multi-tenancy (Varsity/JV/Middle School)
- Currently hardcoded to single team: `11111111-1111-1111-1111-111111111111`
- No team picker UI yet (single-user mode assumed)
- Will be needed when auth is implemented

## Database Schema

### Tables Created:
- `match_drafts` - Draft match configurations (local + Supabase)
- `roster_templates` - Saved roster/rotation templates (Supabase only, no local cache)

### Migration Status:
- `0003_match_drafts.sql` includes both tables
- RLS disabled for development (will re-enable with auth)

## Critical Architecture Issues Identified

### Issue 3: Hardcoded Fallback Data (CRITICAL)
**Problem:**
- `InMemoryMatchSetupRepository` uses hardcoded players with string IDs (`'player-avery'`) that don't match database UUIDs
- When Supabase is not connected, app falls back to hardcoded data, creating entities that can't sync
- This causes ID mismatches when trying to save templates/drafts to Supabase
- **No way to create teams or players in the app** - entities must exist in database first

**Root Cause:**
- Architecture allows creating entities offline with hardcoded data
- No UI for team/player management
- Repository fallback strategy is too permissive

### Issue 4: Missing Multi-Tenancy Support
**Problem:**
- No authentication implemented - all RLS policies disabled
- Hardcoded team ID (`11111111-1111-1111-1111-111111111111`) used everywhere
- No way for different coaches to manage their own teams
- Database schema supports multi-tenancy (`coach_id` on teams) but app doesn't use it

## Recommended Architecture Solution

### Core Principles
1. **Require Supabase Connection for Entity Creation**
   - Teams, players, and templates can ONLY be created when connected to Supabase
   - If offline, show clear message: "Connect to Supabase to create teams and players"
   - Block all entity creation operations when offline

2. **Read-Only Offline Caching**
   - Cache players/teams/templates from Supabase for offline viewing
   - Do NOT allow creating new entities offline
   - Use cached data for display/selection only
   - Show empty state if no cached data available

3. **Remove Hardcoded Fallback**
   - Remove or make `InMemoryMatchSetupRepository` read-only with empty data
   - If Supabase not connected, show empty state with connection prompt
   - Never use hardcoded player/team data

4. **Repository Strategy**
   ```
   Supabase Connected + Authenticated:
     → Use SupabaseMatchSetupRepository (read/write)
     → Cache reads locally for offline viewing
     → Allow entity creation (teams, players, templates)
     → Enforce RLS policies via auth.uid()
   
   Supabase Connected but Not Authenticated:
     → Show authentication screen
     → Block all operations until authenticated
   
   Supabase Not Connected:
     → Use CachedMatchSetupRepository with read-only cache
     → Show empty state if no cached data
     → Block ALL entity creation operations
   ```

## Implementation Plan: Phases 7-10

### Phase 7: Authentication & Multi-Tenancy Foundation 🔐
**Goal:** Implement Supabase Auth with multi-tenant support

**Tasks:**
1. **Auth State Management**
   - Create `AuthProvider` using Riverpod to track auth state
   - Listen to Supabase auth state changes (`onAuthStateChange`)
   - Provide current user ID and session status

2. **Authentication UI**
   - Create `LoginScreen` with email/password authentication
   - Create `SignUpScreen` for new coach registration
   - Add password reset flow
   - Show auth state in app (logged in user, logout button)

3. **Auth Guards**
   - Create `AuthGuard` widget that redirects to login if not authenticated
   - Wrap protected routes with auth guard
   - Show loading state during auth initialization

4. **Team Selection**
   - Create `TeamSelectionProvider` that fetches teams for current coach
   - Query: `SELECT * FROM teams WHERE coach_id = auth.uid()`
   - Create `TeamSelectionScreen` for coaches with multiple teams
   - Store selected team ID in provider (replaces hardcoded `defaultTeamId`)

5. **Update Repository to Use Auth**
   - Modify `SupabaseMatchSetupRepository` to use `auth.uid()` for coach_id
   - Update all queries to filter by authenticated user's teams
   - Remove hardcoded team ID usage

**Files to Create/Modify:**
- `app/lib/features/auth/` (new feature directory)
  - `auth_provider.dart` - Auth state management
  - `login_screen.dart` - Login UI
  - `signup_screen.dart` - Signup UI
  - `auth_guard.dart` - Route protection widget
- `app/lib/features/teams/` (new feature directory)
  - `team_selection_provider.dart` - Team selection state
  - `team_selection_screen.dart` - Team picker UI
- `app/lib/features/match_setup/providers.dart` - Update to use auth/team providers
- `app/lib/features/match_setup/data/supabase_match_setup_repository.dart` - Use auth.uid()

**Database:**
- Re-enable RLS policies (already exist in `0002_rls_policies.sql`)
- Ensure `coach_id` column is properly set on teams
- Test RLS policies with authenticated users

---

### Phase 8: Remove Hardcoded Fallbacks & Add Connection Guards 🚫
**Goal:** Eliminate hardcoded data and enforce Supabase connection for entity creation

**Tasks:**
1. **Refactor Repository Fallback**
   - Remove hardcoded players from `InMemoryMatchSetupRepository`
   - Make it return empty lists when Supabase not connected
   - Add connection check methods to repository interface

2. **Add Connection Guards**
   - Create `SupabaseConnectionGuard` widget
   - Check if Supabase is connected before allowing entity creation
   - Show clear error messages: "Supabase connection required"
   - Add connection status indicator in UI

3. **Update Repository Provider**
   - Modify `matchSetupRepositoryProvider` to check auth state
   - Only use `SupabaseMatchSetupRepository` when authenticated
   - Use read-only cached repository when offline
   - Never fall back to hardcoded data

4. **Error Handling**
   - Add specific error types for "Not Connected" and "Not Authenticated"
   - Show user-friendly error messages
   - Prevent silent failures

**Files to Modify:**
- `app/lib/features/match_setup/data/in_memory_match_setup_repository.dart` - Remove hardcoded data
- `app/lib/features/match_setup/data/match_setup_repository.dart` - Add connection check methods
- `app/lib/features/match_setup/providers.dart` - Update repository selection logic
- `app/lib/core/widgets/connection_guard.dart` (new) - Connection check widget

---

### Phase 9: Team & Player Management UI 👥
**Goal:** Add UI for creating and managing teams and players (Supabase only)

**Tasks:**
1. **Team Management**
   - Create `TeamListScreen` - List all teams for current coach
   - Create `TeamCreateScreen` - Create new team (name, level, season_label)
   - Create `TeamEditScreen` - Edit existing team
   - Add team deletion (with confirmation)
   - Gate all operations behind Supabase connection + auth

2. **Player Management**
   - Create `PlayerListScreen` - List all players for selected team
   - Create `PlayerCreateScreen` - Add new player (name, jersey number, position)
   - Create `PlayerEditScreen` - Edit existing player
   - Add player deletion (with confirmation)
   - Show team context (which team's players are being managed)
   - Gate all operations behind Supabase connection + auth

3. **Navigation Integration**
   - Add "Manage Teams" option to main menu/landing screen
   - Add "Manage Players" option (only visible when team selected)
   - Integrate with match setup flow (select team before setup)

4. **Validation**
   - Validate jersey numbers are unique per team
   - Validate required fields (name, jersey number)
   - Show validation errors clearly

**Files to Create:**
- `app/lib/features/teams/`
  - `team_list_screen.dart`
  - `team_create_screen.dart`
  - `team_edit_screen.dart`
  - `team_providers.dart` - CRUD operations
- `app/lib/features/players/` (new feature directory)
  - `player_list_screen.dart`
  - `player_create_screen.dart`
  - `player_edit_screen.dart`
  - `player_providers.dart` - CRUD operations

**Files to Modify:**
- `app/lib/features/match_setup/match_setup_landing_screen.dart` - Add team/player management links
- `app/lib/features/match_setup/match_setup_flow.dart` - Require team selection first

---

### Phase 10: Read-Only Offline Caching 📱
**Goal:** Cache Supabase data locally for offline viewing (no entity creation)

**Tasks:**
1. **Offline Cache Implementation**
   - Create `OfflineCache` service using Hive or similar
   - Cache teams, players, templates when fetched from Supabase
   - Cache match drafts (already exists, enhance it)
   - Add cache expiration (e.g., 7 days)

2. **Read-Only Repository**
   - Create `ReadOnlyCachedRepository` that only reads from cache
   - Use when Supabase not connected
   - Show empty state if cache is empty
   - Never allow writes

3. **Cache Sync Strategy**
   - On app start: Check Supabase connection
   - If connected: Fetch latest data and update cache
   - If offline: Load from cache (read-only)
   - Show cache status indicator ("Viewing cached data")

4. **UI Updates**
   - Show "Offline" badge when viewing cached data
   - Disable create/edit buttons when offline
   - Show "Connect to Supabase" prompts

**Files to Create:**
- `app/lib/core/cache/offline_cache_service.dart` - Cache management
- `app/lib/features/match_setup/data/read_only_cached_repository.dart` - Read-only repository

**Files to Modify:**
- `app/lib/features/match_setup/data/cached_match_setup_repository.dart` - Enhance caching
- `app/lib/features/match_setup/providers.dart` - Use read-only repo when offline

---

## Next Steps (Immediate)

1. **Phase 7: Start Authentication Implementation**
   - Set up auth providers and UI
   - Test with Supabase local instance
   - Verify RLS policies work with authenticated users

2. **Phase 8: Remove Hardcoded Data**
   - Clean up `InMemoryMatchSetupRepository`
   - Add connection guards
   - Test offline behavior

3. **Phase 9: Build Team/Player Management**
   - Create CRUD screens
   - Integrate with match setup flow
   - Test multi-team scenarios

4. **Phase 10: Implement Offline Caching**
   - Add read-only cache
   - Test offline viewing
   - Verify no entity creation when offline

## Key Files Modified

- `app/lib/features/match_setup/` - All match setup code
- `app/lib/core/theme/` - Dark theme implementation
- `app/lib/core/widgets/glass_container.dart` - Glass morphism components
- `supabase/migrations/0003_match_drafts.sql` - Database schema
- `agent-docs/MATCH-SETUP-IMPROVEMENT-PLAN.md` - Original plan

## Persistence Strategy

- **Drafts:** Hive cache (local) + Supabase (cloud) - dual save
- **Templates:** Supabase only (no local cache) - for multi-device sync
- **Auto-save:** 2s debounce, saves to both local and cloud

