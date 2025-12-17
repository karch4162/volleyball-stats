# Accessibility Testing Checklist

## Automated Testing ✅
- [x] Color contrast tests (WCAG AA 4.5:1 for text, 3:1 for UI components)
- [x] Tooltip presence on all icon buttons
- [x] Semantic labels on interactive elements
- [x] Touch target sizes (minimum 44x44)
- [x] List keys for proper widget identity

## Manual Screen Reader Testing

### Setup Instructions

#### iOS (VoiceOver)
1. Open **Settings** > **Accessibility** > **VoiceOver**
2. Turn on VoiceOver
3. Practice gestures:
   - **Swipe right**: Next element
   - **Swipe left**: Previous element  
   - **Double-tap**: Activate element
   - **Three-finger swipe**: Scroll

#### Android (TalkBack)
1. Open **Settings** > **Accessibility** > **TalkBack**
2. Turn on TalkBack
3. Practice gestures:
   - **Swipe right**: Next element
   - **Swipe left**: Previous element
   - **Double-tap**: Activate element
   - **Two-finger swipe**: Scroll

### Testing Checklist

#### 🏐 Rally Capture Screen
- [ ] Screen announces "Rally Capture" on load
- [ ] Player action buttons announce "Record kill for Player #5 Alice" 
- [ ] Score display announces current score "15 to 12"
- [ ] "Complete Rally" button is focusable and announces action
- [ ] Edit/Stats icon buttons announce their tooltips
- [ ] Recent rallies list announces each rally's outcome
- [ ] Error messages are announced when rally cannot be completed

#### ⚙️ Match Setup Flow
- [ ] Form fields announce labels ("Team Name", "Opponent", "Location")
- [ ] Required fields indicate "required" in announcement
- [ ] Date picker announces selected date
- [ ] Player selection announces "Select 6 players to continue"
- [ ] Rotation grid announces player positions
- [ ] Navigation between steps announces progress
- [ ] Save/Continue buttons announce their state (enabled/disabled)

#### 📊 Dashboard Screens
- [ ] Set dashboard announces "Set 1 Statistics"
- [ ] Player performance cards announce stats in logical order
- [ ] Sort controls announce current sort order
- [ ] Charts have semantic labels describing data
- [ ] Filter buttons announce current filter state
- [ ] Empty state announces "No data available"

#### 👥 Team/Player Management
- [ ] Team list announces each team name
- [ ] "Create Team" button is first focusable element in action bar
- [ ] Form validation errors are announced
- [ ] Delete confirmations announce warning
- [ ] Success messages announce completion

#### 📤 Export Screen
- [ ] Export options are announced clearly
- [ ] CSV/PDF format selection announces current selection
- [ ] Date range picker announces selected range
- [ ] Export progress announces percentage
- [ ] Completion announces success with file location

### Common Issues to Test

#### ❌ Problems to Check For:
1. **Silent elements**: Interactive elements with no announcement
2. **Verbose announcements**: Too much information at once
3. **Wrong focus order**: Tab order doesn't match visual order
4. **Trapped focus**: Can't navigate out of modal/dialog
5. **Missing context**: Buttons announce "Button" instead of action
6. **Redundant announcements**: Icon + text both announced separately

#### ✅ Good Patterns:
1. **Clear labels**: "Edit match details" not just "Edit"
2. **State announcements**: "Sort ascending" vs "Sort descending"
3. **Progress indicators**: "Loading 60%"
4. **Error messages**: "Error: Team name is required"
5. **List context**: "Player 1 of 12"
6. **Action outcomes**: "Team created successfully"

## Keyboard Navigation Testing

### Desktop/Web Testing
- [ ] All interactive elements reachable via Tab key
- [ ] Tab order is logical (top-to-bottom, left-to-right)
- [ ] Shift+Tab navigates backwards correctly
- [ ] Enter/Space activates buttons
- [ ] Escape closes dialogs/modals
- [ ] Arrow keys navigate within lists/grids
- [ ] Focus is visible on all focusable elements

### Focus Indicators
- [ ] Focus ring/outline is visible (not hidden)
- [ ] Focus has sufficient contrast (3:1 minimum)
- [ ] Custom focus styles maintain visibility
- [ ] Focus doesn't get trapped in modals

## Color Contrast Verification

### Automated Results ✅
All color combinations meet WCAG AA requirements:
- ✅ Text on background: 16.30:1 to 3.75:1
- ✅ Accent colors on background: 5.98:1 to 9.59:1
- ⚠️ **Note**: Use dark text (not white) on colored buttons (indigo, rose, emerald)

### Manual Spot Checks
- [ ] All text is readable in bright sunlight
- [ ] Color-blind users can distinguish states
- [ ] Icons supplement color coding (e.g., ❌ for errors, ✓ for success)
- [ ] Charts use patterns in addition to colors

## Text Sizing & Zoom

### Test at Different Scales
- [ ] Test at 200% zoom (WCAG AAA requirement)
- [ ] Text doesn't truncate at large sizes
- [ ] Buttons remain tapable when text grows
- [ ] Layout doesn't break at extreme zoom levels
- [ ] Horizontal scrolling isn't required

## Timing & Motion

### Animation & Transitions
- [ ] No auto-playing animations
- [ ] Respect `prefers-reduced-motion` setting
- [ ] Timeouts have sufficient duration (or are adjustable)
- [ ] No flashing content (< 3 flashes per second)

## Forms & Input

### Form Accessibility
- [ ] All form fields have labels
- [ ] Labels are associated with inputs (not just placeholder)
- [ ] Error messages are clearly linked to fields
- [ ] Required fields are indicated
- [ ] Validation errors are announced
- [ ] Success messages confirm submission

## Multimedia

### Images & Icons
- [ ] Decorative images are marked as decorative
- [ ] Informative images have alt text
- [ ] Icons have tooltips or labels
- [ ] Complex images have extended descriptions

## Testing Tools

### Automated Testing Tools
- ✅ Flutter `flutter test` with accessibility tests
- ✅ Color contrast calculator in test suite
- [ ] Flutter DevTools accessibility inspector

### Manual Testing Tools
- [ ] VoiceOver (iOS)
- [ ] TalkBack (Android)
- [ ] NVDA/JAWS (Windows)
- [ ] ChromeVox (Web)

## Sign-Off

### Accessibility Testing Completed By:
- **Tester Name**: _______________
- **Date**: _______________
- **Platform Tested**: iOS / Android / Web
- **Screen Reader**: _______________
- **Issues Found**: _______________

### Critical Issues (Must Fix):
- [ ] None found / Document issues here

### Medium Priority Issues:
- [ ] None found / Document issues here

### Low Priority Improvements:
- [ ] None found / Document ideas here

## Resources

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [iOS VoiceOver Guide](https://support.apple.com/guide/iphone/turn-on-and-practice-voiceover-iph3e2e415f/ios)
- [Android TalkBack Guide](https://support.google.com/accessibility/android/answer/6283677)

---

**Last Updated**: 2025-12-16
