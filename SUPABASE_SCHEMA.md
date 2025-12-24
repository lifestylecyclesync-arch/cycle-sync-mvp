# Cycle Sync MVP - Database Schema Setup

## Overview
This document contains the correct SQL schema for Cycle Sync MVP based on the tech specs. Replace the previous tables with these.

## ⚠️ IMPORTANT: Delete Old Tables First

Before creating new tables, go to Supabase Dashboard → SQL Editor and run:

```sql
-- Drop old tables (if they exist from previous setup)
drop table if exists user_avatars cascade;
drop table if exists favorites cascade;
drop table if exists goals cascade;
drop table if exists profiles cascade;
```

---

## New Schema: Core MVP Tables

Run these SQL blocks one at a time in Supabase SQL Editor.

### 1️⃣ Users Table

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

### 2️⃣ Cycles Table

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

### 3️⃣ Phases Table

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

### 4️⃣ Goals Table

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

### 5️⃣ Actions Table

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

### 6️⃣ User Preferences Table (Optional but recommended)

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

### 7️⃣ Favorites Table (Optional for storing favorites)

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

---

## Setup Storage Bucket

1. Go to **Storage** in Supabase
2. Create bucket: `user-avatars` (public)
3. Set policy for public reads

---

## Schema Diagram

```
users (1) ──── (many) cycles
              ├─── (many) goals
              ├─── (many) user_preferences
              └─── (many) favorites

cycles (1) ──── (many) phases
              └─── (many) actions

phases (1) ──── (many) actions
```

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| UUIDs for PKs | Better for distributed systems, privacy |
| Enums (phase_enum, goal_type_enum) | Type safety, prevents invalid values |
| Text arrays for dates | Flexible, easy to append/remove |
| RLS policies | GDPR-ready, automatic data isolation |
| No Firebase | Single stack (Supabase only) |

---

## Next Steps

1. ✅ Run all 7 SQL blocks above
2. ✅ Verify tables in Database tab
3. ✅ Update Flutter managers to match new schema
4. ✅ Test with `flutter run`

---

## Migration from Old Tables (if data exists)

If you had test data in old tables:

```sql
-- Example: migrate goals to new schema
insert into goals (user_id, goal_type, target_value, frequency, description)
select user_id, 'fitness'::goal_type_enum, amount, frequency, description
from old_goals;
```

Contact me if you need help migrating data.
