# Google Auth Implementation Checklist

## ✅ Code Already Done

- [x] `google_sign_in` package added to `pubspec.yaml`
- [x] `signInWithGoogle()` method implemented in `SupabaseUserManager`
- [x] Register screen UI with "Sign in with Google" button
- [x] Error handling and user feedback
- [x] Supabase OAuth integration code

## 📝 Configuration Steps (You Need to Do)

### Step 1: Firebase Project Setup
**Time: 5-10 minutes**

Go to [Firebase Console](https://console.firebase.google.com):
1. Create new project: `cycle-sync`
2. Register Android app (package: `com.example.cycle_sync_mvp`)
3. Download `google-services.json`
4. **Place in:** `android/app/google-services.json`

### Step 2: Get Android SHA-1 Fingerprint
**Time: 2 minutes**

Run in terminal:
```powershell
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for: `SHA1: XX:XX:XX:XX:...` and copy this value.

### Step 3: Create Google Cloud Credentials
**Time: 5-10 minutes**

Go to [Google Cloud Console](https://console.cloud.google.com):
1. Enable "Google Sign-In API"
2. Create OAuth 2.0 credentials:
   - **Android:** Use SHA-1 from Step 2
   - **Web:** For Supabase OAuth (get Client ID + Secret)

### Step 4: Enable Google in Supabase
**Time: 5 minutes**

Go to [Supabase Dashboard](https://app.supabase.com):
1. Authentication → Providers → Google
2. Paste Client ID from Google Cloud
3. Paste Client Secret from Google Cloud
4. Add redirect URLs:
   ```
   https://YOUR_PROJECT_URL.supabase.co/auth/v1/callback
   ```

### Step 5: Update Android Build Files
**Time: Already Done! ✅**

The following files are updated:
- [x] `android/app/build.gradle.kts` - Added `com.google.gms.google-services` plugin
- [x] `android/build.gradle.kts` - Added Google Services dependency

### Step 6: (Optional) iOS Setup
**Time: 10 minutes**

If you need iOS support:
1. Create iOS OAuth credentials in Google Cloud
2. Update `ios/Runner/Info.plist` with URL scheme
3. Download Firebase iOS config (optional)

---

## What to Do Next

### Immediate (Today)
1. ✅ Read [GOOGLE_AUTH_SETUP.md](GOOGLE_AUTH_SETUP.md) - Detailed guide
2. ✅ Create Firebase project
3. ✅ Download `google-services.json`
4. ✅ Get Android SHA-1 fingerprint
5. ✅ Create Google Cloud credentials
6. ✅ Enable Google in Supabase
7. ✅ Test on Android

### Testing the Implementation

After completing above:

```bash
# 1. Build and run the app
flutter run

# 2. Open Register screen
# 3. Tap "Sign in with Google"
# 4. Select your Google account
# 5. Should redirect to Onboarding screen

# 6. Verify in Supabase:
# - Dashboard → Authentication → Users
# - You should see new user with provider="google"
```

---

## Success Indicators

✅ **When it works:**
- "Sign in with Google" button appears on Register screen
- Tapping shows Google sign-in dialog
- After selecting account, user is logged in
- Redirects to onboarding
- User appears in Supabase Authentication

❌ **If it fails:**
- Check console output for error messages
- Verify `google-services.json` exists in correct location
- Verify SHA-1 fingerprint matches Google Cloud
- Verify Supabase Google provider is enabled

---

## Files Modified

| File | Change | Status |
|------|--------|--------|
| `android/app/build.gradle.kts` | Added Google Services plugin | ✅ Done |
| `android/build.gradle.kts` | Added Google Services dependency | ✅ Done |
| `android/app/google-services.json` | Need to download and add | 📥 Manual |
| Code (Dart) | Already implemented | ✅ Done |

---

## Quick Command Reference

```bash
# Get SHA-1 fingerprint (Windows)
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# Build and test
flutter run

# Check logs
flutter logs
```

---

## Estimated Time

- **Configuration:** 30-45 minutes (one-time setup)
- **Testing:** 5-10 minutes
- **Total:** ~1 hour

---

## Support

For detailed instructions, see [GOOGLE_AUTH_SETUP.md](GOOGLE_AUTH_SETUP.md)

Questions? The setup guide has troubleshooting section with common issues.
