# Supabase Integration Setup Guide

## Overview
This project now uses **Supabase** as the backend for authentication, data storage, and file uploads. Supabase provides PostgreSQL database, user authentication, real-time subscriptions, and storage capabilities.

## Prerequisites
- Supabase account (free tier available at https://supabase.com)
- Flutter 3.0+ 
- Git configured

## Step 1: Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign in or create an account
3. Create a new project:
   - Click "New Project"
   - Choose organization
   - Project name: `cycle-sync-mvp`
   - Database password: Choose a strong password
   - Region: Select closest to your users
   - Click "Create new project"

4. Wait for project to initialize (2-5 minutes)

## Step 2: Get Your Credentials

1. In your Supabase project, go to **Settings → API**
2. Copy the following:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **Anon Public Key** (labeled as `anon` under `Project API keys`)

3. Update `lib/main.dart`:
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',  // Paste Project URL here
  anonKey: 'YOUR_SUPABASE_ANON_KEY',  // Paste Anon Key here
);
```

## Step 3: Create Database Tables

Go to **SQL Editor** in your Supabase dashboard and run the following SQL:

### 1. Profiles Table
```sql
create table profiles (
  id uuid not null primary key default auth.uid(),
  email text unique,
  name text,
  photo_url text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Enable RLS
alter table profiles enable row level security;

-- Create policy for users to read their own data
create policy "Users can view their own profile"
  on profiles for select
  using (auth.uid() = id);

-- Create policy for users to update their own data
create policy "Users can update their own profile"
  on profiles for update
  using (auth.uid() = id);
```

### 2. Goals Table
```sql
create table goals (
  id text primary key,
  user_id uuid not null,
  name text not null,
  type text not null,
  frequency text not null,
  frequency_value integer not null,
  amount text not null,
  description text,
  completed_dates text[] default array[]::text[],
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint goals_user_id_fkey foreign key (user_id) references profiles(id) on delete cascade
);

-- Enable RLS
alter table goals enable row level security;

-- Policies
create policy "Users can view their own goals"
  on goals for select
  using (auth.uid() = user_id);

create policy "Users can insert their own goals"
  on goals for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own goals"
  on goals for update
  using (auth.uid() = user_id);

create policy "Users can delete their own goals"
  on goals for delete
  using (auth.uid() = user_id);
```

### 3. Favorites Table
```sql
create table favorites (
  id uuid not null primary key default auth.uid(),
  user_id uuid not null unique,
  meals jsonb default '{}',
  workouts text[] default array[]::text[],
  fasting text[] default array[]::text[],
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint favorites_user_id_fkey foreign key (user_id) references profiles(id) on delete cascade
);

-- Enable RLS
alter table favorites enable row level security;

-- Policies
create policy "Users can view their own favorites"
  on favorites for select
  using (auth.uid() = user_id);

create policy "Users can update their own favorites"
  on favorites for update
  using (auth.uid() = user_id);
```

### 4. User Avatars Table
```sql
create table user_avatars (
  id uuid not null primary key default auth.uid(),
  user_id uuid not null unique,
  avatar_id text,
  photo_url text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint user_avatars_user_id_fkey foreign key (user_id) references profiles(id) on delete cascade
);

-- Enable RLS
alter table user_avatars enable row level security;

-- Policies
create policy "Users can view their own avatar"
  on user_avatars for select
  using (auth.uid() = user_id);

create policy "Users can update their own avatar"
  on user_avatars for update
  using (auth.uid() = user_id);
```

## Step 4: Setup Storage Bucket (for profile avatars)

1. Go to **Storage** in Supabase
2. Create a new bucket:
   - Name: `avatars`
   - Make it **Public** (for image URLs)
   - Click "Create bucket"

3. Go to the `avatars` bucket → **Policies** → **New Policy**
4. Add a policy for public reads:
   - Template: `Allow public read access`
   - Click "Review" → "Save policy"

## Step 5: Configure Flutter App

### Android Configuration

1. Open `android/app/build.gradle.kts`
2. Ensure `minSdk` is at least `21`:
```gradle
android {
    defaultConfig {
        minSdk = 21  // or higher
    }
}
```

3. Run: `flutter clean && flutter pub get`

### iOS Configuration

1. Open `ios/Podfile`
2. Ensure platform is at least 12.0:
```ruby
platform :ios, '12.0'
```

3. Run: `flutter clean && flutter pub get`

## Step 6: Install Dependencies

```bash
cd c:\Users\anoua\cycle-sync-mvp
flutter pub get
```

## Step 7: Test the Integration

1. Run the app:
```bash
flutter run
```

2. Test authentication by:
   - Creating a new account
   - Logging in
   - Creating a goal
   - Checking that data persists across app restart

## Architecture Overview

### Service Layer (`lib/services/`)

- **`supabase_service.dart`** - Low-level Supabase client wrapper
  - Authentication methods
  - Database CRUD operations
  - Real-time subscriptions
  - File storage operations

- **`supabase_auth_manager.dart`** - User authentication management
  - Register/login/logout
  - Profile management
  - Password changes

- **`supabase_goal_manager.dart`** - Goal management (replaces local GoalManager)
  - CRUD operations for goals
  - Real-time goal streams
  - Goal filtering by type

- **`supabase_favorites_manager.dart`** - Favorites management
  - Manage favorite meals, workouts, fasting methods
  - Sync across devices

- **`supabase_avatar_manager.dart`** - Avatar management
  - Preset emoji avatars
  - Custom photo uploads to Supabase Storage

## Key Differences from Local Storage

| Feature | Local (SharedPreferences) | Supabase |
|---------|--------------------------|----------|
| Data Persistence | Device only | Cloud + Device |
| Multi-device Sync | ❌ | ✅ |
| Real-time Updates | ❌ | ✅ |
| Offline Support | ✅ | ⚠️ (requires caching) |
| User Accounts | ❌ | ✅ |
| Data Privacy | Local | GDPR compliant* |

*Supabase data is encrypted in transit and at rest.

## Migration from Local Storage (Optional)

If you want to migrate existing local data to Supabase:

1. Read data from SharedPreferences
2. Create Supabase user account
3. Upload local data to Supabase tables
4. Clear local data

Example migration logic can be added to the splash/onboarding screen.

## Real-time Data Syncing

Supabase enables real-time subscriptions. The managers use `subscribeToTable()` for live updates:

```dart
// Listen for goal changes in real-time
SupabaseGoalManager.getGoalsStream(userId)
  .listen((goals) {
    setState(() => this.goals = goals);
  });
```

## Troubleshooting

### "Connection Refused" Error
- Verify your `url` and `anonKey` in `main.dart`
- Ensure your Supabase project is running
- Check your internet connection

### "Authentication Failed"
- Confirm user was registered with Supabase (check Auth in dashboard)
- Check email/password are correct
- Verify email is confirmed (if email confirmation is enabled)

### "Row Level Security" Errors
- Ensure all RLS policies are created correctly
- Verify `auth.uid()` matches user IDs in tables
- Check that user has appropriate permissions

### Image Upload Fails
- Confirm `avatars` bucket exists and is public
- Verify file path format is correct
- Check bucket size limits

## Next Steps

1. **Add authentication UI** - Create login/signup screens
2. **Implement offline caching** - Use local DB for offline mode
3. **Add more features** - Cycle tracking, notifications, etc.
4. **Production setup** - Use different Supabase projects for dev/prod

## Documentation Links

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://supabase.com/docs/reference/flutter/introduction)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
