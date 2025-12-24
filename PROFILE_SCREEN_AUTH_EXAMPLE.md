# Profile Screen Auth Integration Example

This document shows the exact changes needed to add lazy authentication to the Profile Screen.

## Current State
The profile screen saves to SharedPreferences only. Goals are loaded from local GoalManager.

## Required Changes

### 1. Add Import
At the top of `lib/screens/profile_screen.dart`, add:
```dart
import '../utils/auth_guard.dart';
import '../services/supabase_preferences_manager.dart';
import '../services/supabase_goal_manager.dart';
```

### 2. Modify _saveUserData() Method

**Before:**
```dart
Future<void> _saveUserData() async {
  final prefs = await SharedPreferences.getInstance();
  final formattedName = _userName.isEmpty 
      ? '' 
      : _userName[0].toUpperCase() + _userName.substring(1).toLowerCase();
  await prefs.setString('userName', formattedName);
  await prefs.setBool('notificationsEnabled', _notificationsEnabled);
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }
}
```

**After:**
```dart
Future<void> _saveUserData() async {
  // Check if user is logged in before saving
  if (!AuthGuard.isLoggedIn()) {
    final authenticated = await AuthGuard.requireAuth(context);
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in required to save changes'),
            backgroundColor: Color(0xFFDD4444),
          ),
        );
      }
      return;
    }
  }

  try {
    final userId = AuthGuard.getCurrentUserId()!;
    final formattedName = _userName.isEmpty 
        ? '' 
        : _userName[0].toUpperCase() + _userName.substring(1).toLowerCase();

    // Save to Supabase (cloud)
    await PreferencesManager.updateUserPreferences(
      userId: userId,
      name: formattedName,
      avatar: _selectedAvatar?.emoji ?? '👩',
      notificationsEnabled: _notificationsEnabled,
    );

    // Also save to local storage for offline support
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', formattedName);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Color(0xFFDD4444),
        ),
      );
    }
  }
}
```

### 3. Modify Avatar Selection Handler

**Before:**
```dart
void _selectAvatar(AvatarOption avatar) async {
  setState(() {
    _selectedAvatar = avatar;
  });
  await AvatarManager.selectAvatar(avatar);
}
```

**After:**
```dart
void _selectAvatar(AvatarOption avatar) async {
  // Check auth before saving avatar
  if (!AuthGuard.isLoggedIn()) {
    final authenticated = await AuthGuard.requireAuth(context);
    if (!authenticated) {
      return; // User cancelled login
    }
  }

  setState(() {
    _selectedAvatar = avatar;
  });

  try {
    final userId = AuthGuard.getCurrentUserId()!;
    
    // Save to Supabase
    await PreferencesManager.updateAvatar(userId, avatar.emoji);
    
    // Also save locally
    await AvatarManager.selectAvatar(avatar);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

### 4. Update _loadGoals() to Include Cloud Sync

**Before:**
```dart
Future<void> _loadGoals() async {
  try {
    final goals = await GoalManager.getAllGoals();
    setState(() {
      _goals = goals;
    });
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goals not loaded. Tap to refresh.')),
      );
    }
  }
}
```

**After:**
```dart
Future<void> _loadGoals() async {
  try {
    List<dynamic> goals = [];
    
    // Load from cloud if logged in
    if (AuthGuard.isLoggedIn()) {
      final userId = AuthGuard.getCurrentUserId()!;
      goals = await GoalManager.getUserGoals(userId);
    } else {
      // Load from local storage
      goals = await GoalManager.getAllGoals();
    }
    
    setState(() {
      _goals = goals.cast<Goal>();
    });
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goals not loaded. Tap to refresh.')),
      );
    }
  }
}
```

### 5. Update _showEditGoalsDialog() Button Handler

**Before:**
```dart
ElevatedButton(
  onPressed: () async {
    final goal = Goal(
      id: const Uuid().v4(),
      name: _goalNameController.text,
      type: _selectedGoalType!,
      targetValue: double.parse(_goalTargetController.text),
      currentValue: 0,
      unit: _goalUnitController.text,
      createdAt: DateTime.now(),
    );
    await GoalManager.createGoal(goal);
    if (mounted) Navigator.pop(context);
  },
  child: const Text('Add Goal'),
),
```

**After:**
```dart
ElevatedButton(
  onPressed: () async {
    // Require auth to create goal
    if (!AuthGuard.isLoggedIn()) {
      final authenticated = await AuthGuard.requireAuth(context);
      if (!authenticated) return;
    }

    try {
      final userId = AuthGuard.getCurrentUserId()!;
      
      // Create goal (will save to Supabase if logged in)
      final goal = Goal(
        id: const Uuid().v4(),
        userId: userId,
        name: _goalNameController.text,
        type: _selectedGoalType!,
        targetValue: double.parse(_goalTargetController.text),
        currentValue: 0,
        unit: _goalUnitController.text,
        createdAt: DateTime.now(),
      );
      
      // Save to cloud
      await GoalManager.createGoal(goal);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  },
  child: const Text('Add Goal'),
),
```

## Testing This Integration

1. Run the app and go to Profile Screen
2. Try to save settings → Should show login dialog
3. Register new account
4. Settings should save to Supabase
5. Verify in Supabase Dashboard:
   - Check `auth` section → See new user
   - Check `user_preferences` table → See saved avatar, name
   - Check `goals` table → See new goal

## Error Scenarios to Handle

- **No internet**: Supabase calls fail → Catch and show error message
- **User cancelled auth**: Return early from the operation
- **Invalid input**: Validate before creating object
- **Database constraint error**: Show user-friendly message

## Hybrid Storage Strategy

The updated code:
1. **Saves to cloud first** (Supabase) if logged in
2. **Also saves locally** (SharedPreferences) for offline support
3. **Falls back to local** if not logged in

This allows:
- ✅ Offline app usage (local data only)
- ✅ Sync to cloud when logged in
- ✅ Seamless transition from local to cloud

## Why This Pattern?

| Operation | Local Only | Cloud | Hybrid |
|-----------|-----------|-------|--------|
| User explores app | ✅ Works | ❌ Requires login | ✅ Works |
| User logs in | ✅ Local data | ✅ New data | ✅ Both |
| User logs out | ✅ Local data | ❌ Lost | ✅ Kept |
| Sync to other devices | ❌ No | ✅ Yes | ✅ Yes |
| Offline support | ✅ Yes | ❌ No | ✅ Yes |

The hybrid approach gives best UX: works offline, syncs to cloud, persists across login/logout.
