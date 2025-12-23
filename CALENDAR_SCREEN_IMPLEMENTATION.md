# Calendar Screen — Complete State-Action Implementation

## Overview
The Calendar Screen now implements a sophisticated state-action diagram that handles goal tracking with persistent views. Views are added either by active goals or manual selection, and persist even after goal deletion to provide a stable, predictable user experience.

---

## State Implementations

### **State 1: Default (No Goals, No Manual Adds)**
**UI Appearance:**
- Filter dropdown shows only: 📅 Phases
- Calendar shows phase view only
- Days colored by menstrual cycle phase

**Actions:**
- ✅ User sets a goal (e.g., "Exercise 3x/week") → Exercise view appears automatically
- ✅ User manually selects category from "Add category" option → View added without goal
- ✅ Tapping day → Shows phase information only

**Implementation:**
- `_selectedFilter = 'phases'` by default
- `_goals.isEmpty && _manualFilters.isEmpty` condition
- Dropdown shows only phases option

---

### **State 2: Goal Added**
**UI Appearance:**
- Filter dropdown shows: 📅 Phases + Goal types (e.g., 💪 Exercise, 🧘 Meditation)
- Calendar view includes goal tracking
- Days show goal completion colors when viewing goal filter

**Actions:**
- ✅ Tap goal filter → Show goal tracking calendar
- ✅ Tap day while viewing goal → See day details + toggle completions
- ✅ Add another goal → New filter appears automatically in dropdown
- ✅ Add manual category → View added separately

**Implementation:**
- `_getUniqueGoalTypes()` returns unique goal types from `_goals`
- Dropdown includes all goal types with emojis
- `_goalCompletions` tracks completion dates per goal
- `_calculateCombinedGoalProgress()` shows weekly/monthly progress

---

### **State 3: Manual Add (No Goal)**
**UI Appearance:**
- Filter dropdown shows: 📅 Phases + manually added categories (e.g., 💧 Water (no goal))
- Manual filters labeled with "(no goal)" indicator
- Calendar view available but shows "No active goal set for this category" message

**Actions:**
- ✅ Tap "Add category" → Dialog shows available categories
- ✅ Select category → View added to dropdown
- ✅ View persists until manually removed
- ✅ User can later set goal for this category → View becomes goal-tracked

**Implementation:**
- `_manualFilters` Set stores manually added categories
- `_showAddFilterDialog()` shows available categories
- `_saveManualFilters()` persists to SharedPreferences
- Manual filters displayed with "(no goal)" label

---

### **State 4: Goal Deleted (View Persists)**
**UI Appearance:**
- Goal filter still visible in dropdown (now showing "(no goal)" if it was manually added before)
- Calendar shows "No active goal set for this category" message
- View doesn't disappear after deletion

**Actions:**
- ✅ User manually removes filter from dropdown → View disappears
- ✅ User sets new goal for same category → View resumes goal tracking
- ✅ Deletion doesn't disrupt calendar experience

**Implementation:**
- `_removeFilter(goalType)` only removes from `_manualFilters`
- Goal deletion doesn't remove manual filters
- `noGoalMessage` passed to modal when `filteredGoals.isEmpty && _manualFilters.contains(type)`
- Modal shows message with "Set Goal" button linking to profile

---

### **State 5: Multiple Views**
**UI Appearance:**
- Filter dropdown shows: 📅 Phases + all goal types + all manual categories
- Multiple views can be tracked simultaneously
- Each view independent but with consistent filtering

**Actions:**
- ✅ Switch between filters using dropdown
- ✅ Add/Edit/Delete goals → Sync updates dropdown instantly
- ✅ Manual adds/removes → Persist until user manually removes
- ✅ All changes reflected in dropdown immediately

**Implementation:**
- `_selectedFilter` tracks current view
- Dropdown builds items from: phases + goals + manualFilters
- `onChanged` handler switches between views
- All changes trigger `setState()` for immediate UI update

---

## Core Implementation Details

### **Filter State Management**
```dart
String _selectedFilter = 'phases';              // Current filter
List<Goal> _goals = [];                         // Active goals from GoalManager
Set<String> _manualFilters = {};                // Manually added categories
Map<String, Map<DateTime, bool>> _goalCompletions = {}; // Completion tracking
```

### **Manual Filter Persistence**
```dart
// Load from SharedPreferences
Future<void> _loadManualFilters() async {
  final prefs = await SharedPreferences.getInstance();
  final manualFiltersJson = prefs.getString('calendar_manual_filters') ?? '';
  // Parse comma-separated list
}

// Save to SharedPreferences
Future<void> _saveManualFilters() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('calendar_manual_filters', _manualFilters.join(','));
}
```

### **Add Manual Filter Dialog** (`_showAddFilterDialog()`)
- Shows all available categories
- Excludes categories already in goals
- Excludes categories already in manual filters
- On selection: `_addManualFilter(type)` → saves to SharedPreferences

### **Remove Filter** (`_removeFilter(goalType)`)
- Only removes from `_manualFilters`
- Goal deletion doesn't remove manual filters
- If viewing removed filter: reset to 'phases'

### **Dropdown Build Logic**
**Structure:**
1. 📅 Phases (always present)
2. Divider (if goals exist)
3. Goal type filters (from _goals)
4. Divider (if manual filters exist)
5. Manual filters with "(no goal)" label
6. Divider (if any filters exist)
7. Add category option

### **Day Details Modal Updates**

**Message for Manual View Without Goal:**
```
"No active goal set for this category.
Tap to set a goal."
```
- Shows in amber container
- Includes "Set Goal" button → links to profile

**Message Structure:**
- If viewing manual filter without goal: Show no-goal message
- If viewing phases: Show phase info only
- If viewing goal filter with goals: Show progress metrics

---

## User Workflows

### **Workflow 1: Goal → Auto View**
1. User creates goal in Profile (e.g., "Exercise")
2. Return to Calendar
3. Dropdown now shows: 📅 Phases + 💪 Exercise
4. View is automatically available, can be selected

### **Workflow 2: Manual Add → Later Set Goal**
1. User opens Calendar → only Phases visible
2. Taps "Add category" → adds Water manually
3. Dropdown now shows: 📅 Phases + 💧 Water (no goal)
4. Calendar shows "No active goal" message for Water
5. User sets Water goal in Profile
6. Return to Calendar
7. 💧 Water view now tracks completions

### **Workflow 3: Goal Deletion → View Persists**
1. User has Exercise goal tracked
2. Deletes Exercise goal in Profile
3. Return to Calendar
4. 💪 Exercise still in dropdown (added manually before? Or persisted)
5. Shows "No active goal set for this category"
6. User can set new Exercise goal → resumes tracking

### **Workflow 4: Manual Filter Cleanup**
1. User has Water (no goal) manual filter
2. Wants to remove it → (currently no UI for this in dropdown, requires enhancement)
3. Alternative: Dropdown shows manual filters, user can swipe-to-delete or similar

---

## Synchronization

### **Goal Added (ProfileScreen)**
- `_loadGoals()` called → Calendar `_loadGoals()` loads new goals
- Dropdown updated with new goal type
- Manual filters persist unchanged
- If same category exists manually: Goal takes precedence in view

### **Goal Edited**
- Completion dates updated in `_goalCompletions`
- Goal type unchanged → view remains
- Progress metrics recalculated automatically

### **Goal Deleted**
- Manual filter checks: if category was in manual filters, it persists
- Otherwise, category disappears from dropdown
- If currently viewing: reset to 'phases'

### **Manual Filter Added**
- Saved to SharedPreferences immediately
- Dropdown updated instantly
- Available for selection in dropdown

---

## Display Rules

### **Dropdown Items Priority**
1. **Always**: 📅 Phases (baseline)
2. **If Active Goals**: Goal type filters with emojis
3. **If Manual Filters**: Manual category filters with "(no goal)" label
4. **Always**: Add category option

### **View Labeling**
- Active goals: `"💪 Exercise"`
- Manual only: `"💧 Water (no goal)"`
- This distinguishes tracked vs. untracked categories

### **Day Color Logic**
```dart
// When viewing goal_type_exercise:
- Get all Exercise goals
- If goals exist: Show completion colors
- If no goals but manual: Show default (phase colors)

// When viewing phases:
- Always show phase colors
```

### **Modal Messages**
- **Phase view**: Date, phase name, cycle info
- **Goal view with goals**: Progress metrics, goal completions
- **Goal view without goal**: "No active goal set for this category. Tap to set a goal."
- **Manual view without goal**: "(no goal)" label in dropdown + message in modal

---

## Edge Cases

### **Edge Case 1: Goal Deleted, Manual Filter Exists**
- Manual filter persists
- User can later set new goal for same category
- View becomes goal-tracked again

### **Edge Case 2: Multiple Goals Same Type**
- Only one filter per type (e.g., one 💪 Exercise filter for multiple exercise goals)
- Calendar shows combined progress across all goals of type
- Progress shows average or total across goals

### **Edge Case 3: Switching Between Filters**
- State preserved when switching filters
- Can switch multiple times without losing data
- Completion tracking independent per goal

### **Edge Case 4: Manual Filter With Same Name as Goal Type**
- If user manually adds "exercise" and later sets Exercise goal
- Only one filter shows (goal takes precedence)
- View becomes goal-tracked

---

## Error Handling

### **SharedPreferences Failure**
- `_loadManualFilters()` catches exceptions
- Empty set fallback
- Users can re-add manual filters

### **Invalid Goal Data**
- Completion dates validated during parse
- Invalid dates skipped silently
- Doesn't crash calendar

---

## Future Enhancements

- [ ] Swipe-to-delete on manual filters
- [ ] Bulk operations on filters
- [ ] Filter ordering/favorites
- [ ] Filter search functionality
- [ ] Goal completion trends across filters

---

## Testing Checklist

- [ ] Add goal → Filter appears in dropdown
- [ ] Add manual filter → Appears in dropdown with "(no goal)"
- [ ] Switch filters → View updates correctly
- [ ] Delete goal → Manual filter persists if added manually
- [ ] Delete goal → View shows "No active goal" message
- [ ] Set goal for manual category → View tracks completions
- [ ] Remove manual filter → Disappears from dropdown
- [ ] Multiple goals same type → Grouped in one filter
- [ ] Sync with Goals Module → Changes appear immediately
- [ ] SharedPreferences → Manual filters persist across app restart
- [ ] Empty state → Only Phases filter visible

---

## Summary

The Calendar Screen now provides:
- ✅ Predictable view behavior (never disappear unexpectedly)
- ✅ Flexible category tracking (goal-based or manual)
- ✅ Persistent state (manual filters saved)
- ✅ Clear labeling ("(no goal)" for untracked categories)
- ✅ Seamless sync with Goals Module
- ✅ Guidance for users (Set Goal button in modals)
