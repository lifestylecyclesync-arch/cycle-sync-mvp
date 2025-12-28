# Phase 4: Screen Integration - Auth & Data Sync

## Status: READY TO IMPLEMENT ✅

Your app already has:
- ✅ Login/Register screens
- ✅ AuthGuard with `isLoggedIn()` and `getCurrentUserId()`
- ✅ All service managers (goals, cycles, preferences, actions)
- ✅ Database tables created (Phase 3 complete)

**Now:** Connect auth to screens so data saves to Supabase instead of just local storage.

---

## Priority Implementation Order

### Priority 1️⃣: Profile Screen (PARTIALLY DONE)
Status: **50% complete** - `_saveUserData()` has auth check, but needs:
- [ ] Pass `userId` to PreferencesManager
- [ ] Pass `userId` to GoalManager
- [ ] Handle errors with SnackBar

### Priority 2️⃣: Onboarding Cycle Input Screen
Status: **0% complete** - Add auth check before saving cycle

### Priority 3️⃣: Onboarding Lifestyle Screen
Status: **0% complete** - Add auth check before saving preferences

### Priority 4️⃣: Dashboard Screen
Status: **0% complete** - Load cycle/phase from Supabase (if logged in)

### Priority 5️⃣: Other Screens
Status: **0% complete** - Nutrition, Fitness, Fasting, Lifestyle

---

## Quick Architecture Pattern

Every save operation should follow this pattern:

```dart
Future<void> _saveData() async {
  // 1. Check if logged in
  if (!AuthGuard.isLoggedIn()) {
    // 2. If not, show login dialog
    final authenticated = await AuthGuard.requireAuth(context);
    if (!authenticated) return; // User cancelled
  }

  // 3. Get userId
  final userId = AuthGuard.getCurrentUserId()!;

  try {
    // 4. Save to Supabase with userId
    await SomeManager.create(userId: userId, ...);
    
    // 5. Show success
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Saved!'))
    );
  } catch (e) {
    // 6. Show error
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Error: $e'))
    );
  }
}
```

---

## Priority 1: Profile Screen - Complete It

### Current Status
✅ `_saveUserData()` already has auth check at line 74-78
✅ `AuthGuard.requireAuth(context)` already imported

### What's Still Needed
1. Save to `user_preferences` table (currently only local)
2. Save goals with `userId` to Supabase
3. Better error handling

### File: [lib/screens/profile_screen.dart](lib/screens/profile_screen.dart)

**Find:** Line 74-78 (the `_saveUserData()` method)

**Current code:**
```dart
Future<void> _saveUserData() async {
  // Check auth before saving
  if (!AuthGuard.isLoggedIn()) {
    final authenticated = await AuthGuard.requireAuth(context);
    if (!authenticated) return;
  }

  try {
    final userId = AuthGuard.getCurrentUserId()!;
```

**Add after `final userId = ...`:**

Add these imports at the top (if not already there):
```dart
import '../services/supabase_goal_manager.dart';
```

Then update the `_saveUserData()` method to save to Supabase:

**Find the part where it saves to SharedPreferences** (around line 89-100) and add Supabase calls after it:

```dart
// Save preferences to Supabase
await preferences.PreferencesManager.updateUserPreferences(
  userId: userId,
  avatarId: _selectedAvatar?.id,
  theme: 'light',
  notificationsEnabled: _notificationsEnabled,
);

print('✅ User preferences saved to Supabase');
```

**For goals:** Find the section that saves goals locally and ensure it passes `userId`:
```dart
// When creating/updating goals, make sure to include userId
// Example in _createGoal() or similar methods
```

---

## Priority 2: Onboarding Cycle Input Screen

### File: [lib/screens/onboarding_cycle_input_screen.dart](lib/screens/onboarding_cycle_input_screen.dart)

**Pattern to add:**

```dart
// Add imports
import '../utils/auth_guard.dart';
import '../services/supabase_cycle_manager.dart';

// In the "Continue" button onPressed:
_handleContinue() async {
  // 1. Check auth
  if (!AuthGuard.isLoggedIn()) {
    final authenticated = await AuthGuard.requireAuth(context);
    if (!authenticated) return;
  }

  try {
    // 2. Get userId
    final userId = AuthGuard.getCurrentUserId()!;
    
    // 3. Save cycle to Supabase
    await SupabaseCycleManager.createCycle(
      userId: userId,
      cycleLength: _cycleLength,
      periodLength: _periodLength,
      startDate: _lastPeriodStart,
    );

    // 4. Success - navigate
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding_lifestyle');
    
  } catch (e) {
    // 5. Show error
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Error saving cycle: $e'))
    );
  }
}
```

---

## Priority 3: Onboarding Lifestyle Screen

### File: [lib/screens/onboarding_lifestyle_screen.dart](lib/screens/onboarding_lifestyle_screen.dart)

**Same pattern as Priority 2:**

```dart
// Add imports
import '../utils/auth_guard.dart';
import '../services/supabase_preferences_manager.dart';

// In the "Continue" or "Complete" button:
_handleComplete() async {
  // 1. Check auth
  if (!AuthGuard.isLoggedIn()) {
    final authenticated = await AuthGuard.requireAuth(context);
    if (!authenticated) return;
  }

  try {
    // 2. Get userId
    final userId = AuthGuard.getCurrentUserId()!;
    
    // 3. Save preferences to Supabase
    await PreferencesManager.createUserPreferences(
      userId: userId,
      theme: 'light',
      notificationsEnabled: true,
    );

    // 4. Success - navigate to home
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
    
  } catch (e) {
    // 5. Show error
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Error: $e'))
    );
  }
}
```

---

## Priority 4: Dashboard Screen

### File: [lib/screens/dashboard_screen.dart](lib/screens/dashboard_screen.dart)

**Add at startup to load cycle data:**

```dart
// Add imports
import '../utils/auth_guard.dart';
import '../services/supabase_cycle_manager.dart';

@override
void initState() {
  super.initState();
  _loadData();
}

Future<void> _loadData() async {
  try {
    // If user is logged in, load their cycle from Supabase
    if (AuthGuard.isLoggedIn()) {
      final userId = AuthGuard.getCurrentUserId()!;
      final cycles = await SupabaseCycleManager.getUserCycles(userId);
      
      if (cycles.isNotEmpty) {
        // Use their latest cycle
        setState(() {
          // Update UI with Supabase cycle data
        });
        return;
      }
    }
    
    // Otherwise, use local data (SharedPreferences)
    await _loadLocalData();
    
  } catch (e) {
    print('Error loading data: $e');
    // Fall back to local data
    await _loadLocalData();
  }
}

Future<void> _loadLocalData() async {
  final prefs = await SharedPreferences.getInstance();
  // Load from SharedPreferences as before
}
```

---

## Priority 5: Other Screens

For **Nutrition, Fitness, Fasting, Lifestyle** screens:

**Pattern for favorites:**

```dart
// When user taps "Favorite" button
_toggleFavorite(String itemName) async {
  // Check auth
  if (!AuthGuard.isLoggedIn()) {
    final authenticated = await AuthGuard.requireAuth(context);
    if (!authenticated) return;
  }

  try {
    final userId = AuthGuard.getCurrentUserId()!;
    
    // Save to Supabase favorites table
    await FavoritesManager.addToFavorites(
      userId: userId,
      itemName: itemName,
      category: 'nutrition', // or 'fitness', etc.
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ Added to favorites!'))
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'))
    );
  }
}
```

---

## Implementation Checklist

### Profile Screen
- [ ] Verify `_saveUserData()` has auth check
- [ ] Add import for `supabase_goal_manager.dart`
- [ ] Add call to `PreferencesManager.updateUserPreferences(userId, ...)`
- [ ] Test: Open Profile → change settings → check Supabase

### Onboarding Cycle Input
- [ ] Add auth guard check
- [ ] Add `userId` to `SupabaseCycleManager.createCycle()`
- [ ] Add error handling with SnackBar
- [ ] Test: Complete onboarding → check Supabase `cycles` table

### Onboarding Lifestyle
- [ ] Add auth guard check
- [ ] Add `userId` to preferences save
- [ ] Add error handling
- [ ] Test: Complete onboarding → check Supabase `user_preferences` table

### Dashboard Screen
- [ ] Add logic to load from Supabase if logged in
- [ ] Fall back to local data if not logged in
- [ ] Test: After login, cycle info updates from Supabase

### Other Screens
- [ ] Add favorites functionality with auth
- [ ] Test each screen's save operation

---

## Testing Phase 4

**Full flow test:**
1. Close app completely
2. Open app → Welcome screen (no auth required) ✅
3. Go to onboarding → fill cycle info
4. Try to save → **Login dialog appears** ✅
5. Create account with email/password
6. Dialog closes → Continue with onboarding ✅
7. Complete onboarding → goes to dashboard
8. Close and reopen app → **Still logged in** ✅
9. Open Profile → check Supabase → data there ✅

---

## Files to Modify

| File | Priority | Status |
|------|----------|--------|
| [lib/screens/profile_screen.dart](lib/screens/profile_screen.dart) | 1 | 50% (auth check exists, needs userId) |
| [lib/screens/onboarding_cycle_input_screen.dart](lib/screens/onboarding_cycle_input_screen.dart) | 2 | 0% |
| [lib/screens/onboarding_lifestyle_screen.dart](lib/screens/onboarding_lifestyle_screen.dart) | 3 | 0% |
| [lib/screens/dashboard_screen.dart](lib/screens/dashboard_screen.dart) | 4 | 0% |
| [lib/screens/nutrition_suggestions_screen.dart](lib/screens/nutrition_suggestions_screen.dart) | 5 | 0% |
| [lib/screens/fitness_suggestions_screen.dart](lib/screens/fitness_suggestions_screen.dart) | 5 | 0% |
| [lib/screens/fasting_suggestions_screen.dart](lib/screens/fasting_suggestions_screen.dart) | 5 | 0% |
| [lib/screens/lifestyle_syncing_screen.dart](lib/screens/lifestyle_syncing_screen.dart) | 5 | 0% |

---

## Key Differences: Local vs. Supabase

| Operation | Before (Local) | After (Supabase) |
|-----------|---|---|
| Save preference | `SharedPreferences.setString()` | + `PreferencesManager.updateUserPreferences(userId)` |
| Save goal | `GoalManager._saveGoals()` local | + Pass `userId` to cloud |
| Load data | Always local | Check if logged in → Load from cloud, else local |
| Data persistence | Device only | Synced across devices |

---

## Next Steps

1. ✅ **Phase 3 complete** (tables created)
2. 🔄 **Phase 4 in progress** (you are here)
   - Start with Priority 1 (Profile Screen - easiest)
   - Then 2, 3, 4, 5
3. 🧪 **Phase 5:** Test full flow

---

## Questions?

- Check [AUTH_INTEGRATION_GUIDE.md](AUTH_INTEGRATION_GUIDE.md) for auth patterns
- Check [PROFILE_SCREEN_AUTH_EXAMPLE.md](PROFILE_SCREEN_AUTH_EXAMPLE.md) for Profile example
- Check service managers in [lib/services/](lib/services/) for method signatures

**Ready to code?** Start with Priority 1 → Profile Screen!
