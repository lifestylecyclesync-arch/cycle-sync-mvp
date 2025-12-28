# Google Auth Setup - Complete Guide

## Status: Ready to Configure 🚀

Your Flutter app has the Google Sign-In code implemented. Now you need to:
1. ✅ Set up Firebase project
2. ✅ Configure Google OAuth in Supabase
3. ✅ Add Android configuration (google-services.json)
4. ✅ Add iOS configuration (URL scheme)

---

## Phase 1: Firebase Setup

### Step 1.1: Create Firebase Project

1. **Go to:** [Firebase Console](https://console.firebase.google.com)
2. **Click:** "Create a project"
3. **Fill in:**
   - Project name: `cycle-sync` (or similar)
   - Analytics: Leave enabled (or disable if not needed)
4. **Click:** "Create project" (wait 1-2 minutes)

### Step 1.2: Register Android App

1. **In Firebase Console:**
   - Select your project
   - Click **Add app** → **Android**

2. **Fill Android Package Name:**
   - Package name: `com.example.cycle_sync_mvp` (matches your app)
   - App nickname: `Cycle Sync Android` (optional)

3. **Download google-services.json**
   - Firebase will generate this file
   - **IMPORTANT:** Keep this file secure, don't commit to public repos

4. **Place in your project:**
   ```
   android/app/google-services.json
   ```

5. **Click "Next"** and follow any additional setup (you can skip Firebase SDK setup since Supabase handles auth)

### Step 1.3: Get OAuth Credentials

1. **Go to:** [Google Cloud Console](https://console.cloud.google.com)
2. **Create new project** (or select existing)
3. **Enable APIs:**
   - Click "APIs & Services" → "Library"
   - Search "Google Sign-In API"
   - Click "Enable"

4. **Create OAuth 2.0 Credentials:**
   - Click "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth 2.0 Client ID"
   - Choose: "Android"
   - Fill in:
     - Package name: `com.example.cycle_sync_mvp`
     - SHA-1 fingerprint: (see Step 1.4 below)
   - Click "Create"

### Step 1.4: Get SHA-1 Fingerprint (For Android)

**Option A: Using Android Keystore**
```powershell
# Windows (run in terminal)
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the line: `SHA1: XX:XX:XX:XX:...`

**Option B: Using Flutter**
```bash
# Run this in your Flutter project
flutter run -v | grep -i sha
```

**Copy the SHA-1 value** and paste it into Google Cloud Console

---

## Phase 2: Supabase OAuth Setup

### Step 2.1: Enable Google Provider in Supabase

1. **Go to:** [Supabase Dashboard](https://app.supabase.com)
2. **Select your project**
3. **Go to:** Authentication → Providers
4. **Click** on "Google" provider

### Step 2.2: Configure OAuth Details

In the Google provider settings, fill in:

- **Client ID:** (from Google Cloud Console)
  - Found at: Google Cloud Console → Credentials → OAuth 2.0 Client ID (Web)
  
- **Client Secret:** (from Google Cloud Console)
  - Found at: Google Cloud Console → Credentials → OAuth 2.0 Client ID (Web)

**Note:** You may need to create a "Web" application type credential in Google Cloud for the Client ID/Secret (separate from the Android one).

### Step 2.3: Configure Redirect URLs

In Supabase Google provider, add these redirect URLs:
```
https://YOUR_PROJECT_URL.supabase.co/auth/v1/callback
https://YOUR_PROJECT_URL.supabase.co/auth/v1/mobile-callback
```

Replace `YOUR_PROJECT_URL` with your actual Supabase project URL.

**How to find your Supabase URL:**
- Supabase Dashboard → Settings → API → Project URL

---

## Phase 3: Android Configuration

### Step 3.1: Update android/app/build.gradle.kts

Add this to your `build.gradle.kts` at the **plugins** section:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← Add this line
}
```

### Step 3.2: Update android/build.gradle.kts

Add this to the **buildscript** → **dependencies** section (top-level build.gradle):

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.3.15")  // ← Add this
    }
}
```

### Step 3.3: Verify google-services.json

Make sure `google-services.json` exists at:
```
android/app/google-services.json
```

---

## Phase 4: iOS Configuration

### Step 4.1: Get OAuth Client ID (iOS)

1. **Go to:** [Google Cloud Console](https://console.cloud.google.com)
2. **APIs & Services** → **Credentials**
3. **Create new credential:**
   - Type: "OAuth 2.0 Client ID"
   - Application type: "iOS"
   - Fill in:
     - Bundle ID: `com.example.cycleSyncMvp` (find in Xcode)
     - Team ID: (your Apple Team ID)
   - Click "Create"

### Step 4.2: Update Info.plist

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Edit `Info.plist`:**
   - Right-click on "Runner" in Xcode
   - Select "Open as Source Code"
   - Add these keys:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

Replace `YOUR_CLIENT_ID` with your iOS OAuth Client ID from Step 4.1.

### Step 4.3: Update GoogleService-Info.plist (Optional)

If you want Firebase on iOS too:
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to Xcode project (Runner folder)

---

## Phase 5: Test Google Auth

### Android Testing

1. **Build and run on Android device:**
   ```bash
   flutter run
   ```

2. **Test flow:**
   - Open Register screen
   - Tap "Sign in with Google"
   - You should see Google sign-in dialog
   - Select account
   - Should redirect to onboarding
   - Check Supabase → Authentication for new user

### iOS Testing

1. **Build and run on iOS device:**
   ```bash
   flutter run
   ```

2. **Same flow as Android**

### Web Testing (Optional)

Web support requires additional configuration in Google Cloud Console.

---

## Current Implementation Details

Your app already has this working:

### In `lib/services/supabase_user_manager.dart`:

```dart
static Future<bool> signInWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return false;

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw 'Missing tokens';
    }

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

### In `lib/screens/register_screen.dart`:

```dart
Future<void> _handleGoogleSignIn() async {
  setState(() => _isLoading = true);
  try {
    final success = await UserManager.signInWithGoogle();
    if (success && mounted) {
      widget.onRegisterSuccess();
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

---

## Troubleshooting

### "Sign in with Google button does nothing"
- Check: `google-services.json` exists in `android/app/`
- Check: Google Cloud Console has Android credentials configured
- Check: SHA-1 fingerprint matches between Firebase and Google Cloud

### "Google sign in cancelled"
- User tapped cancel button (this is normal)
- App returns `false` from `signInWithGoogle()`

### "Invalid client ID"
- Verify Client ID matches in Supabase Google provider settings
- Check it's from the correct Google Cloud project

### "Redirect URI mismatch"
- Make sure Supabase callback URL is correct:
  - `https://YOUR_PROJECT_URL.supabase.co/auth/v1/callback`
- Check spelling and project URL

### "iOS: Cannot find CFBundleURLSchemes in Info.plist"
- Make sure you added the URL scheme correctly to `Info.plist`
- Check no typos in the CLIENT_ID value

---

## Security Best Practices

✅ **DO:**
- Keep `google-services.json` in `.gitignore` (don't commit to repo)
- Use SHA-1 fingerprint from your actual signing certificate for releases
- Store sensitive keys in environment variables or secure vaults
- Use Supabase RLS policies to protect user data

❌ **DON'T:**
- Commit `google-services.json` to public repos
- Share your OAuth Client Secret
- Use debug keystore SHA-1 for production releases
- Store API keys in source code

---

## Next Steps

1. **Complete Phases 1-5 above** (Firebase + Supabase setup)
2. **Test on Android/iOS** (run the app and tap "Sign in with Google")
3. **Verify in Supabase:**
   - Go to Supabase Dashboard
   - Check Authentication → Users
   - You should see new user created with Google provider
4. **Then proceed to Phase 5 Testing** (full end-to-end testing)

---

## File Changes Required

| File | Change | Status |
|------|--------|--------|
| `android/app/build.gradle.kts` | Add Google Services plugin | 📝 Manual |
| `android/build.gradle.kts` | Add classpath dependency | 📝 Manual |
| `android/app/google-services.json` | Add downloaded file | 📝 Manual |
| `ios/Runner/Info.plist` | Add URL scheme | 📝 Manual |
| Code changes | Already done ✅ | ✅ Complete |

---

## Checklist

- [ ] Created Firebase project
- [ ] Downloaded `google-services.json`
- [ ] Placed in `android/app/`
- [ ] Got SHA-1 fingerprint from keytool or Flutter
- [ ] Created Android credentials in Google Cloud
- [ ] Created Web credentials in Google Cloud
- [ ] Enabled Google provider in Supabase
- [ ] Configured OAuth Client ID/Secret in Supabase
- [ ] Updated `android/app/build.gradle.kts`
- [ ] Updated `android/build.gradle.kts`
- [ ] Created iOS OAuth Client ID (if iOS needed)
- [ ] Updated `ios/Runner/Info.plist` (if iOS needed)
- [ ] Tested on Android device
- [ ] Tested on iOS device (if applicable)
- [ ] Verified user created in Supabase

---

## Questions?

This setup connects:
```
Google OAuth Account
    ↓
Google Sign-In Package (Flutter)
    ↓
Supabase Auth Provider
    ↓
Cycle Sync MVP User Database
```

Once complete, users can register/login with Google in 2 taps! 🎉
