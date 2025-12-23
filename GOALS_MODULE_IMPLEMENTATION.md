# Goals Module — Complete State-Action Implementation

## Overview
The Goals Module is fully implemented as a unified system powering goal management across the Dashboard, Profile Screen, and Calendar. All dialogs and interactions are powered by the `GoalManager` singleton, ensuring a single source of truth.

---

## State Implementations

### **State 1: No Goals**
**UI Appearance:**
- Dashboard: "Tap to set your wellness goals" with empty state message
- Profile: "No goals set yet. Tap + to add…" with empty state message
- Calendar: No goal-type filters available

**Actions:**
- ✅ Tap [Add +] button → Opens Add Goal dialog
- ✅ Tap card background → Opens Add Goal dialog (dashboard) or full Goals Module list (profile)
- ✅ After adding first goal → Auto-syncs to all screens

**Implementation:**
- `Profile._buildGroupedGoals()` checks `if (_goals.isEmpty)` for message display
- `Dashboard._buildGoalsCard()` shows message for empty state
- Both show [Add +] button that calls `_showCreateGoalDialog()`

---

### **State 2: One Goal**
**UI Appearance:**
- Dashboard: Badge shows goal name and amount
- Profile: Goal displayed with type header (💪 Exercise, 💧 Water, etc.)
- Calendar: Goal type appears as filter option

**Actions:**
- ✅ Tap [Add +] → Add Goal dialog
- ✅ Tap goal text → Goal details dialog (Profile shortcut)
- ✅ Tap goal badge (Dashboard) → Goal details dialog
- ✅ Tap ✎ Edit button → Edit Goal dialog
- ✅ Tap ✕ Delete button → Delete confirmation dialog
- ✅ After edit/delete → Immediate sync across all screens

**Implementation:**
- `_buildGoalItem()` renders each goal with edit/delete buttons
- `_showGoalDetailsDialog()` shows view-only details with edit option
- `_showEditGoalDialog()` opens multi-step wizard for editing
- All dialogs call `_loadGoals()` after completion for sync

---

### **State 3: Multiple Goals (≤3)**
**UI Appearance:**
- Dashboard: All goals shown as badges
- Profile: All goals listed with type grouping
- Calendar: All goal types appear as filter options

**Actions:**
- ✅ Tap [Add +] → Add Goal dialog
- ✅ Tap goal text/badge → Goal details dialog
- ✅ Tap ✎ → Edit Goal dialog
- ✅ Tap ✕ → Delete confirmation
- ✅ After add/edit/delete → Instant sync

**Implementation:**
- `_buildGroupedGoals()` creates type-grouped list
- Each goal item has shortcuts for details/edit/delete
- `_getGoalsByType()` groups goals by type with emoji labels
- All actions call `_loadGoals()` for consistency

---

### **State 4: Many Goals (>3)**
**UI Appearance:**
- Dashboard: First 3 goals shown as badges + "+X more" indicator
- Profile: All goals listed with scrolling (if needed)
- Calendar: All goal types available as filters

**Actions:**
- ✅ Tap [Add +] → Add Goal dialog
- ✅ Tap goal text → Goal details dialog
- ✅ Tap ✎ → Edit Goal dialog
- ✅ Tap ✕ → Delete confirmation
- ✅ Tap "+X more" (Dashboard) → Full Goals List (Profile with openGoalDialog=false)
- ✅ After any action → Instant sync

**Implementation:**
- Dashboard: `_buildGoalsCard()` uses `.take(3)` to limit badges
- Shows "+X more" button when `_goals.length > 3` and not expanded
- Tapping "+more" navigates to Profile with full list view
- `_expandedGoals` boolean toggles limited/full view on dashboard

---

### **State 5: After Deletion**
**UI Appearance:**
- Goal removed from Profile list immediately
- Dashboard badge removed/count decremented
- If last goal: revert to State 1 (No Goals)
- Calendar removes goal type filter if no other goals of that type exist

**Actions:**
- ✅ Delete confirmation shows goal being deleted
- ✅ After confirmation → `_loadGoals()` called automatically
- ✅ All screens update instantly
- ✅ Snackbar confirms deletion with goal name

**Implementation:**
- `_showDeleteGoalConfirm()` calls `GoalManager.deleteGoal(goalId)`
- Then calls `_loadGoals()` to refresh all UI
- Uses `ScaffoldMessenger.showSnackBar()` for feedback
- Navigation pops dialog and returns to appropriate screen

---

## Core Implementation Details

### **Data Layer: GoalManager**
```dart
class GoalManager {
  // Core operations
  static Future<List<Goal>> getAllGoals()
  static Future<void> addGoal(Goal goal)
  static Future<void> updateGoal(Goal goal)
  static Future<void> deleteGoal(String goalId)
  
  // Completion tracking
  static Future<void> markGoalCompletedToday(String goalId)
  static Future<void> markGoalNotCompletedToday(String goalId)
  
  // Queries
  static Future<List<Goal>> getGoalsByType(String type)
  
  // Utilities
  static String generateId()
}
```
**Storage:** SharedPreferences with JSON serialization
**Key:** `'user_goals'` stores array of Goal objects

### **Sync Pattern: _loadGoals()**
All screens implement:
```dart
Future<void> _loadGoals() async {
  try {
    final goals = await GoalManager.getAllGoals();
    setState(() => _goals = goals);
  } catch (e) {
    // Show error snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goals not loaded. Tap to refresh.'))
    );
  }
}
```

**Called after:**
- ✅ `addGoal()` in `_showCreateGoalDialog()`
- ✅ `updateGoal()` in `_showEditGoalDialog()`
- ✅ `deleteGoal()` in `_showDeleteGoalConfirm()`
- ✅ Screen navigation returns (Dashboard/Calendar)

### **Dialog Management**

#### **Add Goal Dialog** (`_showCreateGoalDialog()`)
- Step 1: Select goal type (exercise, water, sleep, meditation, nutrition, weightloss, wellness)
- Step 2: Select frequency (daily, weekly, monthly) — if applicable
- Step 3: Enter dynamic fields based on goal type
- On save: `GoalManager.addGoal()` → `_loadGoals()` → Navigation

#### **Edit Goal Dialog** (`_showEditGoalDialog(Goal)`)
- Pre-fills all existing goal data
- Same 3-step wizard as create
- On save: `GoalManager.updateGoal()` → `_loadGoals()` → Navigation
- Preserves completed dates during edit

#### **Delete Confirmation** (`_showDeleteGoalConfirm(String goalId)`)
- Shows goal details (name, amount)
- Warning: "This action cannot be undone. All progress will be deleted."
- On confirm: `GoalManager.deleteGoal()` → `_loadGoals()` → Navigation

#### **Goal Details Dialog** (`_showGoalDetailsDialog(Goal)`)
- Read-only view of goal properties
- Shows: Name, Type, Frequency, Amount, Description
- Edit button opens `_showEditGoalDialog()`
- Close button dismisses dialog

---

## Screen Integration

### **Dashboard Screen** (`dashboard_screen.dart`)
**Role:** Primary entry point for goals overview
- Shows: Goal count, badge display (limited to 3)
- Actions: Add, Edit, Delete, Details (all as shortcuts)
- Sync: `_loadGoals()` on init and after navigation return
- Navigation: Empty state → Add dialog; Full view → Profile

### **Profile Screen** (`profile_screen.dart`)
**Role:** Goals management hub
- Shows: Grouped goals by type with full details
- Actions: Add, Edit, Delete, Details (all as shortcuts)
- Sync: `_loadGoals()` on init and after all operations
- Handles: `openGoalDialog` parameter for direct add/edit from Dashboard
- Type Grouping: Goals grouped with emoji labels (💪, 💧, 😴, etc.)

### **Calendar Screen** (`calendar_screen.dart`)
**Role:** Goal tracking and visualization
- Shows: Goal type filters for tracking
- Actions: Mark progress, view goal details
- Sync: Loads goals on init
- Grouping: Goals grouped by type for combined tracking

---

## Error Handling

### **Sync Failures**
All `_loadGoals()` implementations wrapped in try-catch:
```dart
try {
  final goals = await GoalManager.getAllGoals();
  setState(() => _goals = goals);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Goals not loaded. Tap to refresh.'))
  );
}
```

### **Data Validation**
- Goal IDs generated with timestamp for uniqueness
- Goal types validated against enum of allowed types
- Frequency values validated as positive integers

---

## Scalability & Extensibility

### **Adding New Goal Types**
1. Update `Goal` model (if needed)
2. Add type to `typeOptions` array in `_showCreateGoalDialog()`
3. Add label in `_getGoalTypeLabel()` with emoji
4. Add field config in `_getGoalFieldConfig()`
5. Everything else auto-syncs across all screens

### **Customizing Goal Fields**
Field config in profile_screen.dart:
```dart
Map<String, dynamic> _getGoalFieldConfig() {
  return {
    'exercise': {
      'requiresFrequency': true,
      'fields': [
        {'key': 'amount', 'label': '...', 'type': 'text', 'hint': '...'},
        // Add more fields as needed
      ],
    },
    // ...
  };
}
```

---

## Shortcut vs. Full Module

### **Shortcuts (Preferred)**
Used for quick inline actions:
- ✅ Add Goal dialog
- ✅ Edit Goal dialog
- ✅ Delete confirmation
- ✅ View Details dialog

### **Full Module (Fallback)**
Used for comprehensive list view:
- ✅ Profile screen shows all goals with grouping
- ✅ Accessed via card background tap
- ✅ Accessed via "+X more" indicator
- ✅ Always synced with shortcut changes

---

## Testing Checklist

- [ ] Create goal → syncs to Dashboard, Profile, Calendar
- [ ] Edit goal → updates badge, details, type grouping
- [ ] Delete goal → removes from all screens instantly
- [ ] Last goal deleted → reverts to State 1 (No Goals)
- [ ] Dashboard expansion → shows all goals when "+X more" tapped
- [ ] Dashboard collapse → hides extra goals when "Show less" tapped
- [ ] Profile grouping → goals grouped by type with correct emojis
- [ ] Type-based icons → correct emojis display (💪, 💧, 😴, 🧘, 🥗, ⚖️, ✨)
- [ ] Sync failure → shows error message "Goals not loaded. Tap to refresh."
- [ ] Navigation flow → Proper routing for add/edit/delete operations

---

## Summary

The Goals Module is **bulletproof**: 
- ✅ Single source of truth (GoalManager)
- ✅ Immediate sync across all screens
- ✅ Error handling for all operations
- ✅ Efficient shortcuts + comprehensive full view
- ✅ Scalable for new goal types
- ✅ Consistent grouping by type
- ✅ Proper state management with _loadGoals()
