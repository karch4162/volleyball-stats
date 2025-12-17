# Match Setup Wizard Improvement Plan

## Executive Summary

The current match setup wizard uses a rigid 4-step stepper that requires coaches to manually select players and assign rotations for every match. Since coaches typically use consistent rosters and rotations throughout a season, this creates unnecessary friction. This plan proposes a streamlined approach with saved roster templates, quick-start options, and a more flexible UI that adapts to common workflows.

## Current State Analysis

### Existing Flow
1. **Match Metadata Step**: Opponent, date, location, season label
2. **Roster Selection Step**: Toggle players from full roster (must select at least 6)
3. **Rotation Setup Step**: Assign 6 players to rotation positions 1-6 via dropdowns
4. **Summary Step**: Review and confirm

### Pain Points Identified
1. **Repetitive Selection**: Coaches must manually select the same players every match
2. **Rigid Stepper**: Cannot skip steps or work non-linearly
3. **Rotation Assignment UX**: 6 dropdown menus is tedious and error-prone
4. **No Quick Start**: No way to clone or reuse previous match setups
5. **No Roster Templates**: Cannot save common roster configurations
6. **Validation Friction**: Must complete each step before proceeding
7. **No Draft Persistence**: If user navigates away, selections may be lost

## Proposed Solution: Multi-Modal Match Setup

### Core Concept
Replace the rigid stepper with a flexible, context-aware interface that offers:
- **Quick Start** for common scenarios (clone last match, use template)
- **Saved Roster Templates** for frequently used lineups
- **Streamlined Single-Screen** option for experienced users
- **Progressive Disclosure** showing only what's needed
- **Auto-save Draft** to prevent data loss

---

## Phase 1: Roster Template System

### 1.1 Data Model Extensions

**New Model: `RosterTemplate`**
```dart
class RosterTemplate {
  final String id;
  final String name; // e.g., "Varsity Starters", "JV Rotation A"
  final String? description;
  final Set<String> playerIds; // Selected players
  final Map<int, String> defaultRotation; // Optional: default rotation
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int useCount; // Track frequency for sorting
  
  // Note: Templates include ONLY roster and rotation, NOT match metadata
  // (opponent, date, location are tracked separately per match)
}
```

**Repository Extensions**
- `saveRosterTemplate(template: RosterTemplate)`
- `loadRosterTemplates(): Future<List<RosterTemplate>>`
- `deleteRosterTemplate(id: String)`
- `updateTemplateUsage(id: String)` // Increment useCount, update lastUsedAt

**Storage Strategy**
- Local: Store in Hive/Drift with sync metadata
- Supabase: New `roster_templates` table (optional cloud sync)
- Schema:
  ```sql
  CREATE TABLE roster_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES teams(id),
    name TEXT NOT NULL,
    description TEXT,
    player_ids TEXT[] NOT NULL,
    default_rotation JSONB, -- {1: "player-id", 2: "player-id", ...}
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ,
    use_count INT DEFAULT 0
  );
  ```

### 1.2 Template Management UI

**Template List Screen** (accessible from match setup)
- Grid/list of saved templates
- Each card shows:
  - Template name
  - Player count badge
  - Last used date
  - Quick actions: "Use Template", "Edit", "Delete"
- Floating action button: "Create New Template"
- Search/filter by name

**Template Creation/Edit**
- Similar to current roster selection but with:
  - Name/description fields
  - Option to save current rotation as default
  - "Save as Template" button
- Can be created from:
  - Match setup flow (save current selection)
  - Standalone template manager
  - Previous match (clone as template)

---

## Phase 2: Quick Start Options

### 2.1 Match Setup Landing Screen

**New Entry Point: `MatchSetupLandingScreen`**

When user taps "Start New Match", show:

```
┌─────────────────────────────────────┐
│  Start New Match                    │
├─────────────────────────────────────┤
│                                     │
│  Quick Start Options:               │
│                                     │
│  ┌─────────────────────────────┐  │
│  │ 📋 Use Last Match Setup      │  │
│  │ Clone your previous match    │  │
│  │ [Last used: 2 days ago]      │  │
│  └─────────────────────────────┘  │
│                                     │
│  ┌─────────────────────────────┐  │
│  │ ⭐ Use Template              │  │
│  │ Choose from saved rosters    │  │
│  │ [3 templates available]     │  │
│  └─────────────────────────────┘  │
│                                     │
│  ┌─────────────────────────────┐  │
│  │ ✏️  Start Fresh               │  │
│  │ Build from scratch           │  │
│  └─────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

**Quick Start: Use Last Match**
- Load most recent match draft
- Pre-populate all fields (opponent, roster, rotation)
- Allow editing before saving
- One-tap to start if unchanged

**Quick Start: Use Template**
- Show template picker modal
- Select template → auto-populate roster + rotation
- Edit as needed
- Option to "Use Template" or "Edit Template First"

**Quick Start: Start Fresh**
- Current flow (but streamlined)

### 2.2 Implementation Details

**Provider: `lastMatchDraftProvider`**
```dart
final lastMatchDraftProvider = FutureProvider<MatchDraft?>((ref) async {
  final repo = ref.read(matchSetupRepositoryProvider);
  // Query most recent draft by updated_at
  return await repo.loadMostRecentDraft(teamId: defaultTeamId);
});
```

**Navigation Flow**
```
MatchSetupLandingScreen
  ├─> QuickStartLastMatch → MatchSetupScreen (pre-filled)
  ├─> QuickStartTemplate → TemplatePicker → MatchSetupScreen (pre-filled)
  └─> StartFresh → MatchSetupScreen (empty)
```

---

## Phase 3: Streamlined Single-Screen Setup

### 3.1 Unified Match Setup Screen

Replace stepper with a single scrollable screen that groups related fields:

```
┌─────────────────────────────────────┐
│  Match Setup                        │
├─────────────────────────────────────┤
│                                     │
│  Match Info                         │
│  ┌─────────────────────────────┐  │
│  │ Opponent: [___________]     │  │
│  │ Date: [Mar 15, 2024] 📅    │  │
│  │ Location: [___________]    │  │
│  └─────────────────────────────┘  │
│                                     │
│  Quick Actions                      │
│  [Use Template] [Clone Last Match] │
│                                     │
│  Roster Selection                   │
│  ┌─────────────────────────────┐  │
│  │ ☑ #2 Avery (Setter)          │  │
│  │ ☑ #5 Bailey (Opposite)       │  │
│  │ ☐ #11 Casey (Outside)        │  │
│  │ ...                          │  │
│  └─────────────────────────────┘  │
│                                     │
│  Starting Rotation                  │
│  [Visual rotation grid - see 3.2]  │
│                                     │
│  [Save Draft] [Start Match]        │
└─────────────────────────────────────┘
```

### 3.2 Improved Rotation UI

**Visual Rotation Grid (Selected Approach)**
```
┌─────────────────────────────────────┐
│  Starting Rotation                   │
│                                     │
│      ┌─────┐  ┌─────┐  ┌─────┐    │
│      │  1  │  │  2  │  │  3  │    │
│      │ #2  │  │ #5  │  │ #11 │    │
│      └─────┘  └─────┘  └─────┘    │
│                                     │
│      ┌─────┐  ┌─────┐  ┌─────┐    │
│      │  4  │  │  5  │  │  6  │    │
│      │ #9  │  │ #4  │  │ #7  │    │
│      └─────┘  └─────┘  └─────┘    │
│                                     │
│  Tap a position to assign player   │
└─────────────────────────────────────┘
```

- Tap position → show player picker (only selected roster players)
- Visual feedback: filled positions show jersey number
- Empty positions show position number with "+" indicator
- Drag-and-drop optional (future enhancement)
- **DECIDED**: Proceed with visual grid approach, iterate as needed

### 3.3 Progressive Validation

Instead of blocking navigation:
- **Inline Validation**: Show errors next to fields
- **Smart Suggestions**: 
  - "You've selected 6 players. Want to auto-assign rotation?"
  - "Missing rotation position 3. Tap to assign."
- **Save Draft Anytime**: Allow saving incomplete drafts
- **Warning Indicators**: Visual badges for incomplete sections

---

## Phase 4: Auto-Save & Draft Management

### 4.1 Auto-Save Draft

**Behavior**
- Auto-save draft every 30 seconds after user input
- Save on navigation away (beforeRouteLeave equivalent)
- Save on app background/pause

**Implementation**
- Use `Debouncer` for auto-save (prevent excessive writes)
- Store in local cache immediately
- Sync to Supabase in background if online
- Show subtle indicator: "Draft saved" (non-intrusive)

**Draft Recovery**
- On app restart, prompt: "Resume match setup?"
- Show draft preview (opponent, date, player count)
- Options: "Resume", "Discard", "Save as Template"

### 4.2 Draft History

**Draft List Screen**
- Show all saved drafts (complete and incomplete)
- Sort by: Most recent, By date, By opponent
- Actions per draft:
  - "Continue Setup" (if incomplete)
  - "Clone Match" (create new from this)
  - "Save as Template"
  - "Delete"

**Access Points**
- From match setup landing screen
- From main navigation (if added)
- "Recent Drafts" quick access

---

## Phase 5: Enhanced UX Features

### 5.1 Smart Defaults

**Season Context**
- Auto-detect current season from date
- Pre-fill season label based on date range
- Remember last used season label

**Player Selection**
- Remember last selected players (per season)
- Suggest players based on position (if rotation incomplete)
- Highlight frequently used players

**Rotation Assignment**
- If using template, auto-assign default rotation
- If 6 players selected, offer "Auto-assign rotation" button
- Smart assignment: prioritize by position (setter → position 1, etc.)

### 5.2 Batch Operations

**Roster Selection**
- "Select All" / "Deselect All"
- "Select by Position" (e.g., all Setters)
- "Select Last Match Roster" (quick toggle)

**Rotation Assignment**
- "Clear Rotation" (reset all positions)
- "Swap Positions" (tap two positions to swap)
- "Rotate Left/Right" (shift all players)

### 5.3 Visual Feedback

**Completion Indicators**
- Progress bar showing setup completion %
- Section badges: ✓ Complete, ⚠ Incomplete, ✗ Error
- Player count badge: "6/12 selected"

**Haptic Feedback**
- Light haptic on player toggle
- Medium haptic on rotation assignment
- Success haptic on save

---

## Implementation Phases

### Phase 1: Foundation (Week 1)
- [ ] Create `RosterTemplate` model
- [ ] Extend repository with template CRUD
- [ ] Create template management UI (basic)
- [ ] Add "Save as Template" to match setup

### Phase 2: Quick Start (Week 1-2)
- [ ] Build `MatchSetupLandingScreen`
- [ ] Implement "Use Last Match" flow
- [ ] Implement "Use Template" flow
- [ ] Update navigation to use landing screen

### Phase 3: Streamlined UI (Week 2)
- [ ] Replace stepper with single-screen layout
- [ ] Implement visual rotation grid
- [ ] Add progressive validation
- [ ] Update styling to match dark theme

### Phase 4: Auto-Save (Week 2-3)
- [ ] Implement auto-save debouncer
- [ ] Add draft recovery on app start
- [ ] Create draft history screen
- [ ] Add draft management actions

### Phase 5: Polish (Week 3)
- [ ] Add smart defaults
- [ ] Implement batch operations
- [ ] Enhance visual feedback
- [ ] User testing & refinement

---

## Migration Strategy

### Existing Data
- **Match Drafts**: No changes needed, existing drafts remain valid
- **Roster Data**: No migration needed - users will create templates manually as they use the system

### Backward Compatibility
- Keep stepper flow as fallback (feature flag)
- Allow users to choose: "Classic Stepper" vs "New Flow"
- Gradual rollout: new users get new flow, existing users can opt-in

---

## Success Metrics

### Quantitative
- **Time to Setup**: Reduce from ~3-5 minutes to <1 minute (with template)
- **Template Adoption**: 80% of coaches create at least 1 template within 5 matches
- **Quick Start Usage**: 60%+ of matches use quick start (template or clone)
- **Draft Completion Rate**: Increase from current to >90%

### Qualitative
- User feedback: "Much faster", "Less repetitive"
- Reduced support requests about setup confusion
- Increased match creation frequency (less friction)

---

## Open Questions & Considerations

### Questions
1. **Template Sharing**: Should coaches be able to share templates with other coaches? (Future: team collaboration)
2. **Rotation Validation**: ~~Should we enforce position rules (e.g., setter must be in position 1 or 2)? Or allow free-form?~~ **DECIDED**: No enforcement by default. Optional profile setting for less experienced coaches who want validation hints.
3. **Multiple Templates**: How many templates should we allow per coach? (Recommend: unlimited, but show most-used first)
4. **Template Versioning**: If roster changes (player removed), how to handle templates referencing that player? (Recommend: show warning, allow edit)
5. **Template Scope**: ~~Should templates include match metadata?~~ **DECIDED**: Templates include ONLY roster + rotation. Match metadata (opponent, date, location) tracked separately per match.
6. **Migration**: ~~Auto-create templates from existing drafts?~~ **DECIDED**: No migration needed. Users will create templates manually as they go.

### Technical Considerations
- **Offline Support**: Templates must work fully offline
- **Sync Conflicts**: Handle template sync conflicts gracefully
- **Performance**: Template list should load quickly even with 50+ templates
- **Storage**: Consider template size limits (recommend: max 20 players per template)

### Future Enhancements
- **Rotation Validation Hints**: Optional profile setting for less experienced coaches to show position recommendations (e.g., "Setter typically in position 1 or 2")
- **Match Templates**: Save entire match setups (opponent, roster, rotation) for recurring opponents (if needed)
- **Season Presets**: Pre-configure common season settings
- **Import/Export**: CSV import for rosters, export templates
- **Analytics**: Track which templates/rotations perform best

---

## Appendix: UI Mockups & Wireframes

### Match Setup Landing Screen
```
┌─────────────────────────────────────┐
│  ← Back    Start New Match          │
├─────────────────────────────────────┤
│                                     │
│  Quick Start                        │
│                                     │
│  ┌─────────────────────────────┐  │
│  │ 📋                           │  │
│  │ Use Last Match Setup         │  │
│  │ vs Warriors • Mar 13         │  │
│  │ 6 players • Rotation set     │  │
│  └─────────────────────────────┘  │
│                                     │
│  ┌─────────────────────────────┐  │
│  │ ⭐                           │  │
│  │ Use Template                 │  │
│  │ 3 templates available        │  │
│  └─────────────────────────────┘  │
│                                     │
│  ┌─────────────────────────────┐  │
│  │ ✏️                           │  │
│  │ Start Fresh                  │  │
│  └─────────────────────────────┘  │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Recent Drafts                      │
│  • vs Eagles (Mar 10) - Incomplete│
│  • vs Tigers (Mar 8) - Complete   │
│                                     │
└─────────────────────────────────────┘
```

### Streamlined Match Setup Screen
```
┌─────────────────────────────────────┐
│  ← Back    Match Setup        [💾]  │
├─────────────────────────────────────┘
│                                     │
│  Match Info                    ✓    │
│  ┌─────────────────────────────┐  │
│  │ Opponent: Warriors          │  │
│  │ Date: Mar 15, 2024 📅       │  │
│  │ Location: Home Gym          │  │
│  └─────────────────────────────┘  │
│                                     │
│  Quick Actions                      │
│  [Use Template ▼] [Clone Last]     │
│                                     │
│  Roster Selection           6/12  │
│  ┌─────────────────────────────┐  │
│  │ ☑ #2 Avery (Setter)         │  │
│  │ ☑ #5 Bailey (Opposite)      │  │
│  │ ☑ #11 Casey (Outside)       │  │
│  │ ☑ #9 Devon (Middle)          │  │
│  │ ☑ #4 Elliot (Libero)        │  │
│  │ ☑ #7 Finley (Middle)        │  │
│  │ ☐ #10 Greer (Outside)       │  │
│  └─────────────────────────────┘  │
│                                     │
│  Starting Rotation            ✓    │
│  ┌─────────────────────────────┐  │
│  │      [1]    [2]    [3]      │  │
│  │      #2     #5     #11      │  │
│  │                             │  │
│  │      [4]    [5]    [6]      │  │
│  │      #9     #4     #7       │  │
│  └─────────────────────────────┘  │
│                                     │
│  [Save Draft]  [Start Match →]      │
└─────────────────────────────────────┘
```

---

## Conclusion

This plan addresses the core pain points of the current match setup wizard by introducing roster templates, quick-start options, and a more flexible single-screen interface. The phased approach allows for incremental implementation while maintaining backward compatibility. The focus on reducing repetitive actions and providing smart defaults should significantly improve the coach experience and reduce setup time from minutes to seconds for common scenarios.

