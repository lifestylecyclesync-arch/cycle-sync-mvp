# Phase 3: Database Schema Setup - Step-by-Step

## Status: READY FOR EXECUTION ✅

Your Flutter service managers are **already updated** for the new schema. Now you just need to:
1. Create the database tables in Supabase
2. Create the storage bucket

---

## ⚠️ CRITICAL: Remove Old Tables & Types First

If you've set up Supabase before with the old schema, you MUST delete them first.

**Go to:** Supabase Dashboard → SQL Editor → New Query

**Copy & Run this:**
```sql
-- Drop old tables (if they exist from previous setup)
drop table if exists user_avatars cascade;
drop table if exists favorites cascade;
drop table if exists goals cascade;
drop table if exists profiles cascade;

-- Drop old types (if they exist)
drop type if exists phase_enum cascade;
drop type if exists goal_type_enum cascade;
drop type if exists action_category_enum cascade;
```

Click "Run" and wait for success message.

---

## Step 1: Create Users Table

**Go to:** Supabase Dashboard → SQL Editor → New Query

**Copy & Run:**
```sql
create table users (
  id uuid not null primary key default auth.uid(),
  email text unique not null,
  created_at timestamp with time zone default now()
);

alter table users enable row level security;

create policy "Users can view their own profile"
  on users for select
  using (auth.uid() = id);
```

✅ **Verify:** In Database tab, you should see `users` table with 3 columns.

---

## Step 2: Create Cycles Table

**Go to:** Supabase Dashboard → SQL Editor → New Query

**Copy & Run:**
```sql
create table cycles (
  id uuid not null primary key default gen_random_uuid(),
  user_id uuid not null,
  cycle_length integer not null default 28,
  period_length integer not null default 5,
  start_date date not null,
  created_at timestamp with time zone default now(),
  constraint cycles_user_id_fkey foreign key (user_id) references users(id) on delete cascade
);

alter table cycles enable row level security;

create policy "Users can view their own cycles"
  on cycles for select
  using (auth.uid() = user_id);

create policy "Users can insert their own cycles"
  on cycles for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own cycles"
  on cycles for update
  using (auth.uid() = user_id);

create policy "Users can delete their own cycles"
  on cycles for delete
  using (auth.uid() = user_id);
```

✅ **Verify:** In Database tab, you should see `cycles` table.

---

## Step 3: Create Phases Table

**Go to:** Supabase Dashboard → SQL Editor → New Query

**Copy & Run:**
```sql
create type phase_enum as enum ('menstrual', 'follicular', 'ovulatory', 'luteal');

create table phases (
  id uuid not null primary key default gen_random_uuid(),
  cycle_id uuid not null,
  phase_type phase_enum not null,
  start_day integer not null,
  end_day integer not null,
  created_at timestamp with time zone default now(),
  constraint phases_cycle_id_fkey foreign key (cycle_id) references cycles(id) on delete cascade
);

alter table phases enable row level security;

create policy "Users can view phases of their cycles"
  on phases for select
  using (
    cycle_id in (
      select id from cycles where user_id = auth.uid()
    )
  );
```

✅ **Verify:** In Database tab, you should see `phases` table.

---

## Step 4: Create Goals Table

**Go to:** Supabase Dashboard → SQL Editor → New Query

**Copy & Run:**
```sql
create type goal_type_enum as enum ('hydration', 'sleep', 'fitness', 'nutrition', 'meditation', 'wellness');

create table goals (
  id uuid not null primary key default gen_random_uuid(),
  user_id uuid not null,
  goal_type goal_type_enum not null,
  target_value text not null,
  frequency text not null default 'daily',
  description text,
  completed_dates text[] default array[]::text[],
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint goals_user_id_fkey foreign key (user_id) references users(id) on delete cascade
);

alter table goals enable row level security;

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

✅ **Verify:** In Database tab, you should see `goals` table.

---

## Step 5: Create Actions Table

**Go to:** Supabase Dashboard → SQL Editor → New Query

**Copy & Run:**
```sql
create type action_category_enum as enum ('nutrition', 'fitness', 'lifestyle');

create table actions (
  id uuid not null primary key default gen_random_uuid(),
  phase_id uuid not null,
  category action_category_enum not null,
  description text not null,
  created_at timestamp with time zone default now(),
  constraint actions_phase_id_fkey foreign key (phase_id) references phases(id) on delete cascade
);

alter table actions enable row level security;

create policy "Users can view actions for their phases"
  on actions for select
  using (
    phase_id in (
      select id from phases where cycle_id in (
        select id from cycles where user_id = auth.uid()
      )
    )
  );
```

✅ **Verify:** In Database tab, you should see `actions` table.

---

## Step 6: Create User Preferences Table

**Go to:** Supabase Dashboard → SQL Editor → New Query

**Copy & Run:**
```sql
create table user_preferences (
  id uuid not null primary key default auth.uid(),
  user_id uuid not null unique,
  avatar_id text,
  photo_url text,
  theme text default 'light',
  notifications_enabled boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint user_preferences_user_id_fkey foreign key (user_id) references users(id) on delete cascade
);

alter table user_preferences enable row level security;

create policy "Users can view their own preferences"
  on user_preferences for select
  using (auth.uid() = user_id);

create policy "Users can update their own preferences"
  on user_preferences for update
  using (auth.uid() = user_id);
```

✅ **Verify:** In Database tab, you should see `user_preferences` table.

---

## Step 7: Create Favorites Table

**Go to:** Supabase Dashboard → SQL Editor → New Query

**Copy & Run:**
```sql
create table favorites (
  id uuid not null primary key default gen_random_uuid(),
  user_id uuid not null unique,
  meals jsonb default '{}',
  workouts text[] default array[]::text[],
  fasting text[] default array[]::text[],
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  constraint favorites_user_id_fkey foreign key (user_id) references users(id) on delete cascade
);

alter table favorites enable row level security;

create policy "Users can view their own favorites"
  on favorites for select
  using (auth.uid() = user_id);

create policy "Users can update their own favorites"
  on favorites for update
  using (auth.uid() = user_id);
```

✅ **Verify:** In Database tab, you should see `favorites` table.

---

## Step 8: Create Storage Bucket

1. **Go to:** Supabase Dashboard → Storage (left sidebar)
2. **Click:** "New bucket"
3. **Set:**
   - **Name:** `user-avatars`
   - **Public:** Toggle ON (make it public for image URLs)
4. **Click:** "Create bucket"

5. **Add policy for public reads:**
   - Click on the `user-avatars` bucket
   - Go to **Policies** tab
   - Click **New Policy** → **Get started with templates**
   - Choose: **Allow public read access**
   - Click **Review** → **Save policy**

✅ **Verify:** In Storage tab, you should see `user-avatars` bucket.

---

## Final Verification Checklist

- [ ] ✅ Dropped old tables
- [ ] ✅ Created `users` table
- [ ] ✅ Created `cycles` table
- [ ] ✅ Created `phases` table
- [ ] ✅ Created `goals` table
- [ ] ✅ Created `actions` table
- [ ] ✅ Created `user_preferences` table
- [ ] ✅ Created `favorites` table
- [ ] ✅ Created `user-avatars` storage bucket
- [ ] ✅ Set storage bucket to public

---

## Next Steps After Phase 3

Once all tables are created:

1. ✅ **Phase 3 is complete!**
2. 🔄 **Move to Phase 4:** Screen Integration (auth checks in Profile, Dashboard, etc.)
3. 🔄 **Then Phase 5:** Testing & validation

---

## Troubleshooting

**"Column already exists" error?**
→ You forgot to drop old tables first. Re-run the DROP TABLE commands.

**"Policy creation failed"?**
→ Make sure you created the table first before adding policies.

**Can't see tables in Database tab?**
→ Try refreshing the page in Supabase dashboard.

**"Invalid SQL" error?**
→ Copy-paste the SQL exactly as shown. Make sure you're in the SQL Editor, not elsewhere.

---

## What's Working Now

Your app already has:
- ✅ Login/Register screens
- ✅ Service managers for all tables
- ✅ Auth system (JWT tokens, session management)

Once Phase 3 is done:
- ✅ Data will persist to Supabase
- ✅ Users can save cycles, goals, preferences
- ✅ Data is secure (RLS policies enforce user isolation)

---

**Questions?** Check [SUPABASE_SCHEMA.md](SUPABASE_SCHEMA.md) for the complete schema reference.
