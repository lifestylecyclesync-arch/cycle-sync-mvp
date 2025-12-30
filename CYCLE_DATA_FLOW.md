# Cycle Tracking & Prediction - Data Flow

## Complete Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      CYCLE DATA FLOW                             │
└─────────────────────────────────────────────────────────────────┘

STEP 1: USER INPUT (Onboarding)
═════════════════════════════════════════════════════════════════

User enters:
├── Last Period Start Date (DateTime)
├── Cycle Length (int) - typically 21-35 days
└── Period Length (int) - typically 3-7 days

                    ↓

OnboardingCycleInputScreen
  ├─ Receives input from user
  └─ Calls: supabase_cycle_manager.saveCycleData(userId, data)

                    ↓

STEP 2: DATA PERSISTENCE (Save to Supabase)
═════════════════════════════════════════════════════════════════

supabase_cycle_manager.dart:
  ├─ Creates Cycle object
  ├─ Converts to Map format
  └─ Inserts into Supabase table: cycles

Supabase Table: cycles
┌──────────────────────────────────────────┐
│ Column          │ Type      │ Example    │
├──────────────────────────────────────────┤
│ id              │ UUID      │ abc123...  │
│ user_id         │ UUID      │ user456... │
│ cycle_length    │ INTEGER   │ 28         │
│ period_length   │ INTEGER   │ 5          │
│ start_date      │ DATE      │ 2024-11-28 │
│ created_at      │ TIMESTAMP │ now()      │
└──────────────────────────────────────────┘

                    ↓
          [DATA STORED IN DB]
                    ↓

STEP 3: RETRIEVE & CACHE (Local Caching)
═════════════════════════════════════════════════════════════════

When user opens app:

DashboardScreen.initState()
  ├─ Calls: _loadCycleData()
  └─ Retrieves from Supabase OR uses local cache

supabase_cycle_manager.getCycleData(userId)
  ├─ Queries Supabase for cycles table
  └─ Returns latest Cycle object

Cache Location: SharedPreferences
┌───────────────────────────────────────┐
│ Key                 │ Value           │
├───────────────────────────────────────┤
│ lastPeriodStart     │ 2024-11-28      │
│ cycleLength         │ 28              │
│ periodLength        │ 5               │
└───────────────────────────────────────┘

                    ↓

STEP 4: PHASE CALCULATION (Real-time)
═════════════════════════════════════════════════════════════════

Pure Function: cycle_utils.getCyclePhase()

Input:
  ├─ lastPeriodStart: DateTime (from Supabase)
  ├─ cycleLength: int (from Supabase)
  └─ today: DateTime.now() (current date)

Process:
  1. Calculate days since period started
     dayOfCycle = (today - lastPeriodStart).inDays % cycleLength + 1

  2. Calculate cycle progress (0.0 - 1.0)
     cycleProgress = dayOfCycle / cycleLength

  3. Determine phase based on progress ranges:
     ├─ Menstrual:   0% - 17.9%  (Days 1-5 for 28-day cycle)
     ├─ Follicular:  17.9% - 42.9%  (Days 6-12)
     ├─ Ovulation:   42.9% - 53.6%  (Days 13-15)
     ├─ Early Luteal: 53.6% - 71.4%  (Days 16-20)
     └─ Luteal:      71.4% - 100%  (Days 21-28)

Output: Phase name as String
  └─ "Menstrual" | "Follicular" | "Ovulation" | "Early Luteal" | "Luteal"

                    ↓

STEP 5: PREDICTIONS (Calculated)
═════════════════════════════════════════════════════════════════

Next Period Prediction:
  nextPeriod = lastPeriodStart + (cycleLength * days)
  Example: 2024-11-28 + 28 = 2024-12-26

Ovulation Prediction:
  ovulationDay = cycleLength * 0.429  (approximately day 12 for 28-day)
  ovulationDate = lastPeriodStart + ovulationDay
  Example: 2024-11-28 + 12 = 2024-12-10

Current Cycle Day:
  cycleDay = (today - lastPeriodStart) % cycleLength + 1
  Example: (2024-12-05 - 2024-11-28) % 28 + 1 = Day 8

                    ↓

STEP 6: DISPLAY (UI Screens)
═════════════════════════════════════════════════════════════════

Dashboard Screen shows:
├─ Current Cycle Day: "Day 8 of 28"
├─ Current Phase: "Follicular phase"
├─ Phase Color: Get from getPhaseColor()
├─ Phase Emoji: Get from getPhaseEmoji()
├─ Days to Ovulation: Calculated
└─ Days to Next Period: Calculated

Calendar Screen shows:
├─ Month view with each day colored by phase
├─ Current day highlighted
└─ Cycle phases for entire month

Profile Screen shows:
├─ Cycle Length: 28 days
├─ Period Length: 5 days
├─ Last Period Start: 2024-11-28
└─ Button to update cycle info

                    ↓

STEP 7: UPDATE CYCLE (User edits info)
═════════════════════════════════════════════════════════════════

User navigates to: Profile → "Update Cycle Info"
  ↓
OnboardingCycleInputScreen opens with current values
  ↓
User changes values (e.g., cycle length 28 → 30)
  ↓
supabase_cycle_manager.updateCycleData()
  ├─ Updates Supabase cycles table
  └─ Clears local cache (SharedPreferences)
  ↓
Dashboard automatically recalculates phases
  └─ Because calculations are based on fresh data from Supabase
```

## Data Flow Diagram (Simplified)

```
┌──────────────────┐
│   User Input     │  (Onboarding: period date, cycle length)
│ (Cycle Info)     │
└────────┬─────────┘
         │
         ↓
┌──────────────────────────────────────────┐
│     supabase_cycle_manager.dart          │
│  - saveCycleData(userId, cycle)          │
│  - getCycleData(userId)                  │
│  - updateCycleData(userId, cycle)        │
└────────┬─────────────────────────────────┘
         │
         ↓
    ┌────────────────┐
    │    SUPABASE    │  (Single Source of Truth)
    │   cycles table │  - Stores: cycle_length, period_length, start_date
    └────────┬───────┘
             │
             ↓
   ┌─────────────────────┐
   │ SharedPreferences   │  (Cache for faster access)
   │ (LocalStorage)      │
   └─────────┬───────────┘
             │
             ↓
    ┌────────────────────┐
    │  cycle_utils.dart  │  (Pure Calculation Functions)
    │ - getCyclePhase()  │  - Input: dates, cycle length
    │ - getPhaseColor()  │  - Output: phase name, color, emoji
    │ - getPhaseEmoji()  │
    └────────┬───────────┘
             │
             ↓
    ┌────────────────────────────┐
    │   UI Screens               │
    ├────────────────────────────┤
    │ - DashboardScreen          │  Display: Current phase, cycle day
    │ - CalendarScreen           │  Display: Phase calendar
    │ - ProfileScreen            │  Display: Cycle info
    └────────────────────────────┘
```

## Key Data Points Explained

### 1. **Cycle Day (Current Position)**
- Formula: `(today - lastPeriodStart).inDays % cycleLength + 1`
- Example: If period started Nov 28, today is Dec 5, cycle is 28 days
  - Days elapsed: 7
  - Cycle day: (7 % 28) + 1 = 8
  - Display: "Day 8 of 28"

### 2. **Phase Determination**
- Phases scale proportionally to cycle length
- Formula: `cycleProgress = cycleDay / cycleLength`
- Example for 28-day cycle:
  - Days 1-5: Menstrual (17.9%)
  - Days 6-12: Follicular (25%)
  - Days 13-15: Ovulation (10.7%)
  - Days 16-20: Early Luteal (17.9%)
  - Days 21-28: Luteal (28.6%)

### 3. **Predictions**
- **Next Period**: `lastPeriodStart + Duration(days: cycleLength)`
  - Nov 28 + 28 days = Dec 26
- **Ovulation**: Approximately day 14 for 28-day cycle
  - Calculated: cycleLength * 0.429 ≈ 12 for 28-day

### 4. **Single Source of Truth**
- **Authoritative Source**: Supabase `cycles` table
- **Why**: Ensures consistency across devices, prevents data drift
- **Cache**: SharedPreferences reduces API calls but Supabase is truth
- **Calculation**: All derived from Supabase data, never hardcoded

## Performance Characteristics

| Operation | Time Complexity | Data Source |
|-----------|-----------------|-------------|
| Calculate current phase | O(1) | Pure function, no DB |
| Get cycle day | O(1) | Pure function, no DB |
| Fetch cycle data | O(1) | Supabase query |
| Calendar generation | O(n) where n=days in month | Local calculation |
| Prediction calculation | O(1) | Pure function |

## Example Walkthrough

### Scenario: User registers and sets up cycle

**Day 1 - Onboarding:**
```
User: "My last period was Nov 28, cycle is 28 days"
  ↓
saveCycleData(userId="user123", {
  cycle_length: 28,
  period_length: 5,
  start_date: "2024-11-28"
})
  ↓
[Saved to Supabase cycles table]
```

**Day 2 - Dashboard loads:**
```
DashboardScreen._loadCycleData()
  ↓
getCycleData("user123")
  ↓
[Fetch from Supabase, cache in SharedPreferences]
  ↓
cycleLength = 28
lastPeriodStart = 2024-11-28
today = 2024-11-29
  ↓
cycleDay = (1 % 28) + 1 = 2
cycleProgress = 2/28 = 0.071 (7.1%)
phase = "Menstrual" (< 17.9%)
  ↓
Display: "Day 2 • 🩸 Menstrual phase"
       "Next period: Dec 26"
```

**Day 30 - User edits cycle info:**
```
ProfileScreen: "Update Cycle Info"
  ↓
User changes: cycleLength 28 → 30
  ↓
updateCycleData("user123", {cycle_length: 30})
  ↓
[Update Supabase, clear SharedPreferences cache]
  ↓
DashboardScreen refreshes automatically
  ↓
New calculations use cycleLength = 30
  ↓
Next period now: Dec 28 (instead of Dec 26)
```

## Testing Data Flow

### Unit Tests
```dart
// Test phase calculation
test('calculates menstrual phase correctly', () {
  final lastPeriod = DateTime(2024, 11, 28);
  final today = DateTime(2024, 11, 29);
  final phase = getCyclePhase(lastPeriod, 28, today);
  expect(phase, 'Menstrual');
});

// Test cycle day calculation
test('calculates cycle day correctly', () {
  final lastPeriod = DateTime(2024, 11, 28);
  final today = DateTime(2024, 12, 5); // 7 days later
  final cycleDay = (today.difference(lastPeriod).inDays % 28) + 1;
  expect(cycleDay, 8);
});
```

### Integration Tests
```dart
// Test full flow
test('saves and retrieves cycle data', () async {
  await supabase_cycle_manager.saveCycleData(
    userId: 'test_user',
    cycleLength: 28,
    periodLength: 5,
    lastPeriodStart: DateTime(2024, 11, 28),
  );
  
  final cycle = await supabase_cycle_manager.getCycleData('test_user');
  expect(cycle.cycleLength, 28);
  expect(cycle.startDate, DateTime(2024, 11, 28));
});
```

## Summary

The data flow is **unidirectional and deterministic**:
1. User enters cycle info once (or updates it)
2. Stored in Supabase (single source of truth)
3. Retrieved and cached locally
4. Pure functions calculate everything else
5. UI displays calculated results
6. Changes cascade automatically

This ensures consistency, performance, and correctness across the entire app.
