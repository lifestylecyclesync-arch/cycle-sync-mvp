# Authentication Integration Guide

## Overview
This guide shows how to integrate lazy authentication into screens that save data to Supabase. Users can explore the app without logging in, but must authenticate when saving data.

## How It Works

1. **`AuthGuard`** - Utility class in [lib/utils/auth_guard.dart](lib/utils/auth_guard.dart)
   - `AuthGuard.isLoggedIn()` - Check if user is authenticated
   - `AuthGuard.requireAuth(context)` - Show login/register dialog if needed
   - `AuthGuard.guardAction()` - Guard async actions with auth check

2. **Three Authentication Screens**
   - [lib/screens/login_screen.dart](lib/screens/login_screen.dart) - Email/password login
   - [lib/screens/register_screen.dart](lib/screens/register_screen.dart) - Account creation
   - Dialog in `auth_guard.dart` - Shows login/register in a modal overlay

## Integration Patterns

### Pattern 1: Simple Button Click with Auth Check

```dart
// Before: No auth check
ElevatedButton(
  onPressed: () async {
    await GoalManager.createGoal(/* params */);
  },
  child: const Text('Save Goal'),
),

// After: With auth check
ElevatedButton(
  onPressed: () async {
    // Check if logged in, show dialog if not
    if (!AuthGuard.isLoggedIn()) {
      final authenticated = await AuthGuard.requireAuth(context);
      if (!authenticated) return; // User cancelled
    }
    
    try {
      await GoalManager.createGoal(/* params */);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal saved!')),
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
  child: const Text('Save Goal'),
),
```

### Pattern 2: Using guardAction() Helper (Recommended)

```dart
ElevatedButton(
  onPressed: () async {
    await AuthGuard.guardAction(
      context,
      () async {
        // This code only runs if user is authenticated
        await GoalManager.createGoal(
          userId: AuthGuard.getCurrentUserId()!,
          type: GoalType.hydration,
          // other params...
        );
        return true; // Return whatever you want
      },
      errorMessage: 'You must be logged in to save goals',
    );
  },
  child: const Text('Save Goal'),
),
```

### Pattern 3: Multiple Save Operations

```dart
Future<void> _saveAllChanges() async {
  // Check once at the start
  if (!AuthGuard.isLoggedIn()) {
    final authenticated = await AuthGuard.requireAuth(context);
    if (!authenticated) return;
  }
  
  try {
    // Then perform multiple saves
    await GoalManager.updateGoal(/* ... */);
    await PreferencesManager.updateAvatar(/* ... */);
    await CycleManager.updateCycle(/* ... */);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All changes saved!')),
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

## Screens That Need Auth Checks

Based on the MVP, these screens have "Save" operations:

1. **Profile Screen** - Save avatar, name, preferences
2. **Goal Creation** - Create/edit goals
3. **Cycle Input Screen** - Save cycle start date
4. **Lifestyle Preferences Screen** - Save lifestyle settings
5. **Any suggestions screen** - If user can "favorite" items

## Integration Checklist

Each screen needing updates should:

- [ ] Import `auth_guard.dart`
- [ ] Add `AuthGuard.isLoggedIn()` check before save operations
- [ ] Show `AuthGuard.requireAuth(context)` dialog if needed
- [ ] Get `userId` from `AuthGuard.getCurrentUserId()` when saving
- [ ] Pass `userId` to all service methods (GoalManager, CycleManager, etc.)

## Example: Profile Screen Integration

```dart
// File: lib/screens/profile_screen.dart

import '../../utils/auth_guard.dart'; // Add this import

class _ProfileScreenState extends State<ProfileScreen> {
  // ... existing code ...
  
  Future<void> _saveUserData() async {
    // Check auth before saving to cloud
    if (!AuthGuard.isLoggedIn()) {
      final authenticated = await AuthGuard.requireAuth(context);
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must log in to save changes')),
          );
        }
        return;
      }
    }
    
    try {
      final userId = AuthGuard.getCurrentUserId()!;
      
      // Save to Supabase
      await PreferencesManager.updateUserPreferences(
        userId: userId,
        name: _userName,
        avatar: _selectedAvatar?.emoji ?? '👩',
        notificationsEnabled: _notificationsEnabled,
      );
      
      // Also save to local (for offline support)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _userName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
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
}
```

## Testing Auth Flow

1. Start the app → Should go to onboarding (no login required)
2. Explore onboarding screens → Should work without auth
3. Try to create a goal → Should show login dialog
4. Go to Register tab → Create account
5. After registration → Should be able to save data
6. Check Supabase → Should see user and their data

## Key Points

- **LocalStorage still used**: SharedPreferences for offline support
- **Lazy auth pattern**: Auth only required when saving to cloud
- **Dialog overlay**: Login/register appears as modal, not new screen
- **User ID required**: All Supabase operations need `AuthGuard.getCurrentUserId()`
- **Error handling**: Catch and display errors from Supabase operations

## Migration Path

1. ✅ Create login_screen.dart
2. ✅ Create register_screen.dart  
3. ✅ Create auth_guard.dart
4. ✅ Initialize AuthGuard in main.dart
5. 🔄 Update screens to use AuthGuard (priority: profile, goals, cycle input)
6. 🔄 Test with Supabase DB schema created

## Debug Tips

If auth isn't working:

1. Check if `AuthGuard.initialize()` was called in main.dart
2. Verify Supabase credentials in main.dart
3. Check Supabase console → Auth → Users (should see new registrations)
4. In ProfileScreen, check `UserManager.isLoggedIn()` returns true after login
5. Check error messages in ScaffoldMessenger SnackBars
