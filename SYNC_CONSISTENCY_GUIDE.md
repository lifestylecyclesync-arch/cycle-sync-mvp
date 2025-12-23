# Sync Consistency Guide - CycleSync MVP

## Overview
This document ensures consistency across Dashboard, Profile, and Calendar screens by enforcing a single sync pattern.

## Sync Strategy: Bulletproof Pattern

### Single Source of Truth
- **GoalManager** is the exclusive data source for all goal operations
- All CRUD operations go through GoalManager
- All data persists to SharedPreferences via GoalManager
- No direct modifications to Goal objects after creation

### The Bulletproof Sync Pattern

**Every goal modification follows this exact flow:**

```
User Action (Create/Edit/Delete)
    ↓
await GoalManager.operation()  ← Waits for persistence
    ↓
await _loadGoals()             ← Reloads all goals into state
    ↓
setState() triggered           ← UI updates automatically
    ↓
All 3 screens sync instantly   ← Consistent across Dashboard/Profile/Calendar
```

### Implementation Details

#### 1. **Create Goal**

**Dashboard & Profile:**
```dart
await GoalManager.addGoal(newGoal);
await _loadGoals();
if (mounted) {
  Navigator.pop(context); // Close dialog
}
```

**Rule:** Always `await` both operations before navigation.

#### 2. **Update Goal**

**Dashboard, Profile, & Calendar:**
```dart
final updatedGoal = goal.copyWith(
  name: newName,
  amount: newAmount,
  description: newDescription,
);
await GoalManager.updateGoal(updatedGoal);
await _loadGoals();
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

**Rule:** Must recreate Goal object (final fields) and await both operations.

#### 3. **Delete Goal**

**Dashboard, Profile, & Calendar:**
```dart
await GoalManager.deleteGoal(goalId);
await _loadGoals();
if (context.mounted) Navigator.pop(context);
```

**Rule:** Always await both operations. Manual filters persist even after goal deletion.

#### 4. **Mark Completion** (Calendar only)

```dart
final dateStr = DateFormat('yyyy-MM-dd').format(date);
goal.completedDates.add(dateStr); // or remove()
await GoalManager.updateGoal(goal);
await _loadGoals();
```

**Rule:** Update completedDates then await both operations.

### Sync Lifecycle Hooks

#### **initState** (All screens)
```dart
@override
void initState() {
  super.initState();
  _loadCycleData();    // Load cycle info (async)
  _loadGoals();        // Load goals (async)
  _loadManualFilters(); // Load calendar filters (async)
}
```

#### **didChangeDependencies** (All screens)
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _loadGoals();        // Reload when returning from navigation
}
```

**Why:** Ensures latest data after returning from another screen.

### State Variables - Guaranteed Consistent

All screens maintain identical state:
```dart
List<Goal> _goals = [];  // Single list, loaded from GoalManager
```

**Dashboard badges** ← shows `_goals` count/data
**Profile list** ← shows `_goals` grouped by type
**Calendar filters** ← shows `_goals` types

All three consume the same `_goals` list.

### Error Handling

**Network/Persistence errors:**
- GoalManager catches SharedPreferences exceptions
- If persist fails, user sees error and data reverts
- _loadGoals() validates all data before setState()

**UI state consistency:**
- All navigations check `if (mounted)` before setState()
- Prevents state updates on disposed screens
- Prevents race conditions

### Testing Consistency

**Verification checklist:**
- [ ] Add goal in Dashboard → appears in Profile & Calendar
- [ ] Edit goal in Profile → updates in Dashboard & Calendar  
- [ ] Delete goal in Calendar → removed from Dashboard & Profile
- [ ] Return to Dashboard after profile edit → shows latest data
- [ ] All three screens show same goal counts
- [ ] Manual filters persist after goal deletion

### Common Anti-Patterns (AVOID)

❌ **Don't:** Use `.then()` callbacks instead of `await`
```dart
// WRONG - May navigate before _loadGoals() completes
GoalManager.addGoal(goal).then((_) {
  _loadGoals(); // Race condition
  Navigator.pop(context);
});
```

✅ **Do:** Use async/await
```dart
// CORRECT - Waits for completion before navigating
await GoalManager.addGoal(goal);
await _loadGoals();
if (mounted) Navigator.pop(context);
```

---

❌ **Don't:** Modify Goal fields directly (they're final)
```dart
// WRONG - Goal fields are immutable
goal.name = "New Name";
goal.amount = "5";
```

✅ **Do:** Create new Goal object
```dart
// CORRECT - Immutable pattern
final updatedGoal = goal.copyWith(
  name: "New Name",
  amount: "5",
);
await GoalManager.updateGoal(updatedGoal);
```

---

❌ **Don't:** Skip _loadGoals() after operations
```dart
// WRONG - State won't update
await GoalManager.deleteGoal(goalId);
Navigator.pop(context); // No sync!
```

✅ **Do:** Always reload after operations
```dart
// CORRECT - Syncs all screens
await GoalManager.deleteGoal(goalId);
await _loadGoals(); // Guarantees sync
if (mounted) Navigator.pop(context);
```

### Why This Pattern Works

1. **Sequential Execution** - `await` ensures operations complete in order
2. **Single State Update** - `_loadGoals()` triggers one setState() per operation
3. **No Race Conditions** - Navigation waits for sync before proceeding
4. **Automatic UI Sync** - All screens share same `_goals` list
5. **Data Integrity** - GoalManager handles persistence atomically

### Future Enhancements

If adding more features:
- **Notifications:** Show after `await _loadGoals()` completes
- **Undo/Redo:** Create new operation in GoalManager
- **Offline Mode:** Queue operations, sync when online
- **Real-time Sync:** Replace GoalManager with Firebase/backend

All still follow the same `await operation → await _loadGoals()` pattern.

---

## Summary

**One Pattern, Three Screens, Zero Inconsistencies:**

```
Persist → Reload → Update UI → Consistent State
```

Every goal operation follows this. No exceptions. No shortcuts. Bulletproof.
