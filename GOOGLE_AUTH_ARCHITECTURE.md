# Google Auth Architecture & Flow

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    USER'S GOOGLE ACCOUNT                    │
│                  (google.com/accounts)                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│          GOOGLE SIGN-IN SERVICE (Android/iOS)               │
│                                                              │
│  - Shows sign-in dialog                                     │
│  - Returns ID Token + Access Token                          │
│  - Managed by google_sign_in package                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              CYCLE SYNC MVP (Flutter App)                   │
│                                                              │
│  SupabaseUserManager.signInWithGoogle()                     │
│  ├─ GoogleSignIn.signIn()                                  │
│  ├─ Get tokens from Google                                 │
│  └─ Call Supabase with tokens                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                 SUPABASE AUTH SERVICE                       │
│                                                              │
│  - Receives ID Token + Access Token                         │
│  - Validates with Google OAuth provider                     │
│  - Creates user in database if new                          │
│  - Returns JWT session token                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓
┌─────────────────────────────────────────────────────────────┐
│             SUPABASE POSTGRES DATABASE                      │
│                                                              │
│  users table:                                               │
│  ├─ id (from Google)                                        │
│  ├─ email (from Google)                                     │
│  ├─ created_at                                              │
│  └─ provider: 'google'                                      │
│                                                              │
│  user_preferences table:                                    │
│  ├─ notifications_enabled                                   │
│  ├─ avatar_id                                               │
│  └─ theme                                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## OAuth 2.0 Token Flow

```
1. User clicks "Sign in with Google" button
   ↓
2. Google Sign-In package shows dialog
   ↓
3. User selects Google account
   ↓
4. Google server validates credentials
   ↓
5. Google returns:
   - ID Token (contains user info)
   - Access Token (for API access)
   ↓
6. App sends tokens to Supabase
   ↓
7. Supabase validates tokens with Google
   ↓
8. Supabase creates/updates user in database
   ↓
9. Supabase returns JWT session
   ↓
10. App stores JWT and redirects to onboarding
```

---

## Implementation Details

### Step 1: User Initiates Sign-In

**File:** `lib/screens/register_screen.dart`

```dart
// User taps "Sign in with Google" button
Future<void> _handleGoogleSignIn() async {
  setState(() => _isLoading = true);
  try {
    final success = await UserManager.signInWithGoogle();
    if (success && mounted) {
      widget.onRegisterSuccess();  // Go to onboarding
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

### Step 2: Get Tokens from Google

**File:** `lib/services/supabase_user_manager.dart`

```dart
static Future<bool> signInWithGoogle() async {
  try {
    // Step 1: Create Google Sign-In instance
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    // Step 2: Show Google sign-in dialog
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      print('Google sign in cancelled');
      return false;  // User cancelled
    }

    // Step 3: Get authentication details
    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw 'Missing tokens';
    }

    // Step 4: Send to Supabase
    final response = await SupabaseService.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    print('Google sign in successful: ${response.user?.email}');
    return response.user != null;
  } catch (e) {
    print('Google sign in error: $e');
    return false;
  }
}
```

### Step 3: Supabase Creates User

When tokens arrive, Supabase:
1. Validates ID Token with Google's servers
2. Extracts user info (email, name, picture)
3. Creates `users` table entry with `id` from Google
4. Creates `user_preferences` entry (with defaults)
5. Generates JWT session token
6. Returns to app

### Step 4: App Stores Session

```dart
// Supabase automatically stores JWT in secure storage
// (handled by supabase_flutter package)

// Next requests use JWT:
// Authorization: Bearer <JWT_TOKEN>
```

---

## Configuration Connections

### Firebase ↔ Google Cloud ↔ Supabase

```
┌──────────────────┐
│  Firebase Project│
│                  │
│ - Manages Google │
│   Sign-In for    │
│   Android        │
│                  │
│ google-services. │
│ json generated   │
└────────┬─────────┘
         │
         ↓
┌──────────────────┐        ┌──────────────────┐
│ Google Cloud     │        │   Supabase       │
│                  │        │                  │
│ - OAuth 2.0      │───────→│ - Google Provider│
│   Credentials    │        │   Settings       │
│ - Client ID      │        │ - Client ID      │
│ - Client Secret  │        │ - Client Secret  │
│                  │        │ - Redirect URLs  │
└──────────────────┘        └──────────────────┘
```

---

## What Each File Does

### `google-services.json` (Android)
- Downloaded from Firebase
- Tells Android app how to connect to Google Services
- Contains Firebase project configuration
- **Where:** `android/app/google-services.json`

### `android/app/build.gradle.kts`
- Applies Google Services plugin
- Line: `id("com.google.gms.google-services")`

### `android/build.gradle.kts`
- Adds Google Services dependency
- Line: `classpath("com.google.gms:google-services:4.3.15")`

### `lib/services/supabase_user_manager.dart`
- Implements `signInWithGoogle()` method
- Communicates with Google Sign-In package
- Sends tokens to Supabase

### `lib/screens/register_screen.dart`
- UI for "Sign in with Google" button
- Calls `UserManager.signInWithGoogle()`
- Handles navigation after success

---

## Data Flow Example

### Before Sign-In
```
Device (App) ─→ (not authenticated)
```

### During Sign-In
```
Device App
  ↓
[User clicks Google button]
  ↓
Google Sign-In Dialog
  ↓
[User selects account]
  ↓
Google servers validate
  ↓
Return tokens to app
  ↓
App sends tokens to Supabase
  ↓
Supabase validates with Google
  ↓
Supabase creates/updates user
  ↓
Return JWT to app
  ↓
App stores JWT (secure storage)
```

### After Sign-In
```
Device (App) ←→ Supabase (JWT authorized)
                   ↓
              User can now:
              - Create goals
              - Save preferences
              - Track cycles
              - View personal data
```

---

## Security Flow

```
┌─────────────────────────────────────────────┐
│        User's Google Credentials            │
│    (Never shared with app directly)         │
└──────────────────┬──────────────────────────┘
                   │ (stays on Google servers)
                   ↓
┌─────────────────────────────────────────────┐
│      Google Sign-In Package                 │
│  (Handles credential validation securely)   │
└──────────────────┬──────────────────────────┘
                   │
                   ↓ (only tokens, no password)
┌─────────────────────────────────────────────┐
│        Cycle Sync MVP App                   │
│  (Receives: ID Token, Access Token)         │
│  (Does NOT receive: Google password)        │
└──────────────────┬──────────────────────────┘
                   │
                   ↓ (tokens only)
┌─────────────────────────────────────────────┐
│        Supabase Auth Service                │
│  (Validates tokens with Google)             │
│  (Returns: JWT session token)               │
└──────────────────┬──────────────────────────┘
                   │
                   ↓ (JWT stored securely)
┌─────────────────────────────────────────────┐
│      App's Secure Storage                   │
│  (JWT token: Used for all requests)         │
│  (Tokens never exposed to user)             │
└─────────────────────────────────────────────┘
```

**Key Points:**
- User's Google password never touches your app
- Only tokens are transmitted
- Tokens validated by Supabase with Google
- User data protected by RLS policies

---

## Testing the Flow

### Step 1: Start App
```bash
flutter run
```

### Step 2: Go to Register Screen
```
Home → Register tab
```

### Step 3: Tap "Sign in with Google"
```
Button appears (if google-services.json is correct)
↓
Tap button
↓
Google dialog appears
↓
Select Google account
```

### Step 4: Verify Success
```
App returns to Register screen
↓
Should show "Signing up..." briefly
↓
Then navigate to Onboarding
↓
Check console for: "Google sign in successful: user@gmail.com"
```

### Step 5: Check Supabase
```
Supabase Dashboard
  ↓
Authentication → Users
  ↓
Look for new user with provider="google"
```

---

## Troubleshooting Flow

```
Google button doesn't appear?
  ↓
→ google-services.json missing in android/app/

Google button appears but nothing happens when tapped?
  ↓
→ Check SHA-1 fingerprint matches Google Cloud
→ Check Android credentials created in Google Cloud

Google dialog appears but shows error?
  ↓
→ Check Firebase project ID in google-services.json
→ Check package name is correct

Sign-in succeeds but user not created in Supabase?
  ↓
→ Check Supabase Google provider is enabled
→ Check Client ID/Secret are correct in Supabase
→ Check redirect URLs in Supabase

User created but app crashes after sign-in?
  ↓
→ Check onboarding screen exists
→ Check error logs: flutter logs
```

---

## Next: Production Deployment

For Google Play Store / App Store:

1. **Android:**
   - Get SHA-1 from production keystore
   - Create prod OAuth credentials in Google Cloud
   - Update google-services.json (or use Firebase Remote Config)

2. **iOS:**
   - Create iOS OAuth credentials
   - Update Info.plist URL scheme
   - Update Supabase redirect URLs

3. **Supabase:**
   - Update redirect URLs for production domain
   - Enable RLS policies (already done)
   - Set up database backups

See [GOOGLE_AUTH_SETUP.md](GOOGLE_AUTH_SETUP.md) for detailed instructions.
