# Quick Reference: Lazy Authentication

## What Was Just Created

### 3 New Files
1. **`login_screen.dart`** - Email/password login UI
2. **`register_screen.dart`** - Email/password registration UI  
3. **`auth_guard.dart`** - Authentication state & dialog overlay

### 4 Documentation Files
1. **`AUTHENTICATION_IMPLEMENTATION.md`** - Overview of auth setup
2. **`AUTH_INTEGRATION_GUIDE.md`** - Integration patterns for screens
3. **`PROFILE_SCREEN_AUTH_EXAMPLE.md`** - Step-by-step example
4. **`IMPLEMENTATION_CHECKLIST.md`** - Complete progress tracker

### 1 Modified File
- **`main.dart`** - Added `AuthGuard.initialize()`

## How It Works (User Flow)

```
User opens app
    ↓
Onboarding screens (no login required) ✅
    ↓
User clicks "Save" button (e.g., add goal)
    ↓
AuthGuard checks: "Is user logged in?"
    ↓
  If NO: Shows login/register dialog 🔐
    ├─ User registers → Creates Supabase account
    ├─ AuthGuard updates state
    └─ Dialog closes
    ↓
  If YES: Continues to save
    ↓
Save operation executes
    ├─ Gets userId from AuthGuard
    ├─ Saves to Supabase
    ├─ Shows success SnackBar ✅
    └─ Updates UI
    ↓
User data synced to cloud ☁️
```

## The 3 Auth Screens

### Login Screen
- Email field
- Password field
- "Sign In" button
- "Create account" link
- Error messages
- Loading spinner

**Usage:** Shows when user needs to log in

### Register Screen
- Email field
- Password field
- Confirm password field
- Terms checkbox
- "Create Account" button
- "Already have account?" link
- Error messages
- Loading spinner

**Usage:** Shows when user clicks "Create account"

### Auth Guard
Not a screen - a helper class that:
- Stores login state
- Shows login/register dialog
- Provides auth check methods
- Guards async operations

**Usage:** 
```dart
if (!AuthGuard.isLoggedIn()) {
  await AuthGuard.requireAuth(context); // Shows dialog
}
```

## Quick Integration Recipe

### For Any "Save" Button

```dart
// 1. Import auth_guard
import '../utils/auth_guard.dart';

// 2. In your save handler
Future<void> _handleSave() async {
  // Check auth
  if (!AuthGuard.isLoggedIn()) {
    final ok = await AuthGuard.requireAuth(context);
    if (!ok) return; // User cancelled
  }
  
  // Get user ID
  final userId = AuthGuard.getCurrentUserId()!;
  
  // Save with userId
  try {
    await MyService.save(userId: userId, /* ... */);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

## Before You Test

### CRITICAL: Create Database Schema

The auth screens work, but they need a database. You must run SQL in Supabase:

**Steps:**
1. Open Supabase Dashboard → https://app.supabase.com
2. Select your project
3. Go to SQL Editor (left sidebar)
4. Click "New Query"
5. Go to [SUPABASE_SCHEMA.md](SUPABASE_SCHEMA.md)
6. Copy SQL Block 1
7. Paste in SQL Editor
8. Click "Run"
9. Repeat for Blocks 2-7

**This creates 7 tables:**
- users ✔ Auth system
- cycles ✔ Cycle tracking
- phases ✔ Auto-calculated phases
- goals ✔ User goals
- actions ✔ Phase recommendations
- user_preferences ✔ Settings
- favorites ✔ Saved items

**Without this, registration "works" but data won't save.**

## Testing Checklist

- [ ] Database schema created in Supabase (7 tables)
- [ ] Run `flutter pub get` (✅ already done)
- [ ] Open app → See Welcome screen
- [ ] Go through onboarding
- [ ] Click any "Save" button
- [ ] See login/register dialog
- [ ] Click "Create Account"
- [ ] Enter email: test@example.com
- [ ] Enter password: Password123
- [ ] Check "I agree to terms"
- [ ] Click "Create Account"
- [ ] Dialog should close
- [ ] Previous action should complete (goal saved, etc.)
- [ ] Open Supabase → Check `auth` section → See new user
- [ ] Check `goals` table → See saved goal

## If Something Breaks

### Login dialog won't show
- Check `auth_guard.dart` imported correctly
- Check `AuthGuard.initialize()` in `main.dart`
- Check no compilation errors: `flutter pub get`

### Registration fails with error
- Check Supabase credentials in `main.dart`
- Check internet connection
- Check Supabase project is live
- Check `users` table exists in Supabase

### Data doesn't save
- Check user was created in Supabase → `auth` section
- Check `goals` table exists in Supabase
- Check userId is passed to save method
- Check internet connection

### "Already logged in" but can't save
- Check `AuthGuard.getCurrentUserId()` returns non-null
- Check service manager methods accept `userId` parameter
- Check Supabase credentials are correct

## Key Concepts

| Term | Meaning |
|------|---------|
| **AuthGuard** | Helper class managing login state |
| **Lazy Auth** | Auth only when saving, not upfront |
| **Dialog Overlay** | Login screens appear as modal, not full screen |
| **userId** | Unique ID from Supabase, needed for all saves |
| **isLoggedIn()** | Returns true if user has valid session |
| **requireAuth()** | Shows dialog if not logged in |
| **guardAction()** | Wrapper that auto-guards async operations |

## File Locations

```
Auth Screens:
  lib/screens/login_screen.dart (283 lines)
  lib/screens/register_screen.dart (330 lines)

Auth Guard:
  lib/utils/auth_guard.dart (186 lines)

Service Layer (already done):
  lib/services/supabase_user_manager.dart
  lib/services/supabase_*.dart

Updated:
  lib/main.dart (added initialization)

Docs:
  SUPABASE_SCHEMA.md (database setup)
  AUTHENTICATION_IMPLEMENTATION.md
  AUTH_INTEGRATION_GUIDE.md
  PROFILE_SCREEN_AUTH_EXAMPLE.md
  IMPLEMENTATION_CHECKLIST.md
```

## Next Steps Priority

**Immediate (required):**
1. ⚠️ Create database schema in Supabase (7 SQL blocks)

**Short term (this week):**
2. Update Profile Screen to use AuthGuard
3. Update Cycle Input to use AuthGuard
4. Test complete flow

**Medium term (when working):**
5. Update other screens (goals, lifestyle, etc.)
6. Add hybrid storage (local + cloud)
7. Error handling refinement

**Long term (future):**
8. Social login (Google, Apple)
9. Password reset
10. 2FA

## No Compilation Errors ✅

All 4 new/modified files verified:
- ✅ login_screen.dart - No errors
- ✅ register_screen.dart - No errors
- ✅ auth_guard.dart - No errors
- ✅ main.dart - No errors

Ready to test once you create database schema!

---

**Status:** Lazy auth implementation complete, waiting for database schema setup
