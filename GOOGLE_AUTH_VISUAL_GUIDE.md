# Google Auth Visual Setup Guide

## 1️⃣ Firebase Console Setup

### Screenshot Guide: Create Project

```
firebase.google.com/console
                     ↓
              [Create a project]
                     ↓
    ┌─────────────────────────────┐
    │ Project name: cycle-sync    │
    │ Google Analytics: Enable    │
    │ [Create project]            │
    └─────────────────────────────┘
                     ↓
            (Wait 1-2 minutes)
                     ↓
         [Project created!]
```

### Register Android App

```
Your Project Page
       ↓
    [Add app]
       ↓
   [Android]
       ↓
    ┌──────────────────────────────────────┐
    │ Package name:                        │
    │ com.example.cycle_sync_mvp           │
    │                                      │
    │ App nickname (optional):             │
    │ Cycle Sync Android                   │
    │                                      │
    │ [Next] → [Register app]              │
    └──────────────────────────────────────┘
       ↓
Download google-services.json
       ↓
Place in: android/app/
```

### Where Files Go

```
your-project/
├── android/
│   └── app/
│       ├── build.gradle.kts
│       └── google-services.json  ← Downloaded from Firebase
├── ios/
├── lib/
└── pubspec.yaml
```

---

## 2️⃣ Get SHA-1 Fingerprint

### Windows Terminal

```powershell
# Copy & paste this entire command:
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# Output will look like:
# ─────────────────────────────
# Alias name: androiddebugkey
# Creation date: Jan 1, 2023
# Entry type: PrivateKeyEntry
# Certificate chain length: 1
# Certificate[1]:
#   Owner: CN=Android Debug, O=Android, C=US
#   ...
#   SHA1: 12:34:56:78:AB:CD:EF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC
#          ↑
#          Copy this value (without colons for Google Cloud)
```

**For Google Cloud use:** `1234567890ABCDEF001122334455667788990AABBCC` (remove colons)

---

## 3️⃣ Google Cloud Console Setup

### Create OAuth Credentials

```
console.cloud.google.com
       ↓
   [Select Project]
       ↓
   [Create New Project: cycle-sync]
       ↓
   APIs & Services → Library
       ↓
   Search: "Google Sign-In API"
       ↓
   [Google Sign-In API] → [Enable]
       ↓
   APIs & Services → Credentials
       ↓
   [+ Create Credentials] → [OAuth 2.0 Client ID]
```

### Create Android Credential

```
Application type: Android
       ↓
┌────────────────────────────────┐
│ Package name:                  │
│ com.example.cycle_sync_mvp     │
│                                │
│ SHA-1 fingerprint:             │
│ 1234567890ABCDEF...            │
│ (from Step 2)                  │
│                                │
│ [Create]                       │
└────────────────────────────────┘
       ↓
Android OAuth Client created! ✅
(You won't need Client ID for Android,
 but keep it for reference)
```

### Create Web Credential

```
Application type: Web
       ↓
┌──────────────────────────────────┐
│ Name: Cycle Sync Web             │
│                                  │
│ Authorized JavaScript origins:   │
│ (leave blank for now)            │
│                                  │
│ Authorized redirect URIs:        │
│ https://YOUR_PROJECT_URL.        │
│ supabase.co/auth/v1/callback     │
│                                  │
│ [Create]                         │
└──────────────────────────────────┘
       ↓
┌──────────────────────────────────┐
│ Client ID: (copy this)           │
│ xxx.apps.googleusercontent.com   │
│                                  │
│ Client Secret: (copy this)       │
│ GOCSPX-xxxxxxxxxxxxx            │
└──────────────────────────────────┘
```

**Save these! You'll need them for Supabase.**

---

## 4️⃣ Supabase Configuration

### Find Your Project URL

```
app.supabase.com
       ↓
   [Select Project]
       ↓
   Settings → API
       ↓
   Copy: Project URL
   Example: https://abc123xyz.supabase.co
```

### Enable Google Provider

```
app.supabase.com
       ↓
Authentication → Providers
       ↓
   [Google] (toggle to enabled)
       ↓
┌────────────────────────────────────┐
│ Enable Google                      │
│ Toggle: ON ✓                       │
│                                    │
│ Client ID:                         │
│ [Paste from Google Cloud]          │
│                                    │
│ Client Secret:                     │
│ [Paste from Google Cloud]          │
│                                    │
│ Redirect URLs:                     │
│ https://YOUR_PROJECT_URL.         │
│ supabase.co/auth/v1/callback      │
│                                    │
│ [Save]                             │
└────────────────────────────────────┘
       ↓
    Google Provider Enabled! ✅
```

---

## 5️⃣ Android Build Configuration

### Update android/app/build.gradle.kts

```kotlin
Before:
────────
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

After:
──────
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  ← ADD THIS
}
```

### Update android/build.gradle.kts

```kotlin
Before:
────────
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

After:
──────
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

buildscript {                              ← ADD THIS
    dependencies {                         ← BLOCK
        classpath(                         ← 
            "com.google.gms:google-services:4.3.15"
        )                                  ←
    }                                      ←
}                                          ←
```

---

## 6️⃣ Test on Device

### Build & Run

```bash
flutter run
```

### Test Flow

```
App Opens
       ↓
Register Tab
       ↓
[Sign in with Google] button
       ↓
TAP BUTTON
       ↓
Google Sign-In Dialog appears ✅
       ↓
Select Google Account
       ↓
Dialog closes
       ↓
"Signing up..." appears briefly
       ↓
Redirected to Onboarding Screen ✅
       ↓
Check console: "Google sign in successful: user@gmail.com"
```

### Verify in Supabase

```
app.supabase.com
       ↓
Authentication → Users
       ↓
Look for new user:
┌────────────────────────────────┐
│ Email: user@gmail.com          │
│ Provider: google               │
│ Created: Just now              │
│ Status: Active ✓               │
└────────────────────────────────┘
```

---

## Visual: Complete Data Flow

```
┌──────────────────────────────────────────┐
│  User taps "Sign in with Google"         │
└──────────────────┬───────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────┐
│  Google Sign-In Dialog appears           │
│  (shows list of Google accounts)         │
└──────────────────┬───────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────┐
│  User selects account & authorizes       │
└──────────────────┬───────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────┐
│  Google servers validate credentials     │
│  Return: ID Token + Access Token         │
└──────────────────┬───────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────┐
│  App receives tokens                     │
│  Sends to: Supabase Auth Service         │
└──────────────────┬───────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────┐
│  Supabase validates tokens with Google   │
│  Creates user in database                │
│  Returns JWT session                     │
└──────────────────┬───────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────┐
│  App stores JWT in secure storage        │
│  Redirects to Onboarding Screen          │
│  User can now use app! ✅                │
└──────────────────────────────────────────┘
```

---

## Checklist with Screenshots

### After Firebase Setup
```
✅ Project created in Firebase
✅ Android app registered
✅ google-services.json downloaded
✅ Placed in android/app/
✅ SHA-1 fingerprint obtained
```

### After Google Cloud Setup
```
✅ Google Sign-In API enabled
✅ Android OAuth credentials created
✅ Web OAuth credentials created
✅ Client ID copied
✅ Client Secret copied
```

### After Supabase Setup
```
✅ Google provider enabled
✅ Client ID pasted
✅ Client Secret pasted
✅ Redirect URLs configured
```

### After Android Build Updates
```
✅ android/app/build.gradle.kts updated
✅ android/build.gradle.kts updated
```

### After Testing
```
✅ "Sign in with Google" button works
✅ Google dialog appears
✅ User can select account
✅ App redirects to onboarding
✅ User visible in Supabase
```

---

## Common Issues & Solutions

### Issue: Can't find google-services.json
```
Solution: 
- Download from Firebase
- Place in: android/app/
- Exact location matters!
```

### Issue: "Invalid SHA-1"
```
Solution:
- Re-run keytool command
- Copy full value (without colons)
- Paste into Google Cloud Console
```

### Issue: Google button doesn't appear
```
Solution:
- Check google-services.json exists
- Rebuild: flutter clean && flutter run
```

### Issue: Sign-in succeeds but user not in Supabase
```
Solution:
- Check Google provider is ENABLED in Supabase
- Check Client ID/Secret are correct
- Check redirect URLs are correct
```

---

## Summary

**You've completed:**
✅ Code implementation (already done)
✅ Documentation (created)

**You need to do:**
1. Firebase setup (5 min)
2. Get SHA-1 (2 min)
3. Google Cloud setup (10 min)
4. Supabase configuration (5 min)
5. Build updates (auto-done)
6. Test (5 min)

**Total time:** ~30-45 minutes

Good luck! 🚀
