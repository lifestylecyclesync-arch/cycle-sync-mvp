# Phase Logic Update Summary

## Overview
Updated all phase calculation logic to match the new adaptive phase prediction table provided by the user. This replaces the previous 5-day ovulation window (OD-2 to OD+2) with more nuanced boundaries.

## Updated Phase Boundaries

### Generic Formula (for any cycle length)
```
Day 1 → (ML-1):           Power Phase → Menstrual → IF 13h
Day ML:                   Power Phase → Menstrual → IF 15h
Day (ML+1) → (ML+5):      Power Phase → Follicular → IF 17h
Day (ML+6) → (OD-2):      Manifestation → Follicular → IF 13h
Day (OD-1) → (OD+1):      Manifestation → Ovulation → IF 13h
Day (OD+2) → (OD+5):      Power Phase → Early Luteal → IF 15h
Day (OD+6) → CycleLength: Nurture Phase → Luteal → No fasting
```

### Concrete Example (28-day cycle: ML=5, OD=14)
| Day Range | Lifestyle Phase | Hormonal Phase | IF Duration | Workout Type |
|-----------|---|---|---|---|
| Days 1–4 | Power | Menstrual | 13h | Gentle strength / restorative |
| Day 5 | Power | Menstrual | 15h | Gentle strength / restorative |
| Days 6–10 | Power | Follicular | 17h | High-intensity, strength-focused |
| Days 11–12 | Manifestation | Follicular→Ovulation | 13h | Strength & resistance training |
| Days 13–15 | Manifestation | Ovulation | 13h | Strength & resistance training |
| Days 16–19 | Power | Early Luteal | 15h | High-intensity, strength-focused |
| Days 20–28 | Nurture | Luteal | No fasting | Restorative, low-impact workouts |

## Files Updated

### 1. [lib/utils/cycle_utils.dart](lib/utils/cycle_utils.dart)
- **getCyclePhase()**: Refactored to use new boundaries
  - Follicular: Days (ML+1) to (OD-2) [was (OD-1)]
  - Ovulation: Days (OD-1) to (OD+1) [was (OD-2) to (OD+2)]
  - Early Luteal: Days (OD+2) to (OD+5) [was (OD+3) to (OD+7)]

- **getDaysUntilNextPhase()**: Updated phase end days
  - Uses new boundary calculations for each phase

### 2. [lib/services/supabase_cycle_manager.dart](lib/services/supabase_cycle_manager.dart)
- **getPhaseRange()**: Updated all 5 phase boundaries
  - follicular: Days (periodLength + 1) to (ovulationDay - 2)
  - ovulatory: Days (ovulationDay - 1) to (ovulationDay + 1)
  - early_luteal: Days (ovulationDay + 2) to (ovulationDay + 5)
  - luteal: Days (ovulationDay + 6) to cycleLength

### 3. [lib/screens/dashboard_screen.dart](lib/screens/dashboard_screen.dart)
- **_getPhaseRanges()**: Updated display ranges for all phases
  - Shows correct day ranges in dashboard UI

### 4. [lib/screens/lifestyle_syncing_screen.dart](lib/screens/lifestyle_syncing_screen.dart)
- **_getPhaseRange()**: Updated phase range display in settings
  - All 5 phases now show correct day ranges

### 5. [lib/screens/calendar_screen.dart](lib/screens/calendar_screen.dart)
- **_getPhaseExtension()**: Updated phase range display
- **_buildUpcomingHighlightsPanel()**: Fixed phase end day calculations
  - Follicular ends at (OD-2) not (OD-3)
  - Ovulation ends at (OD+1) not (OD+2)
  - Early Luteal ends at (OD+5) not (OD+7)

## Key Changes from Previous Logic

| Aspect | Previous | New | Reason |
|--------|----------|-----|--------|
| **Follicular End** | Day (OD-1) / Day 12 | Day (OD-2) / Day 12 | More accurate follicular duration |
| **Ovulation Window** | Days (OD-2) to (OD+2) = 5 days | Days (OD-1) to (OD+1) = 3 days | Narrower peak ovulation period |
| **Ovulation Start** | Day 12 (with follicular) | Day 13 (separate phase) | Clear phase transition |
| **Early Luteal Duration** | 5 days (OD+3 to OD+7) | 4 days (OD+2 to OD+5) | More accurate early luteal |
| **Luteal Duration** | 7 days (OD+8 to 28) | 9 days (OD+6 to 28) | Extended luteal recognition |

## Phase Transition Example (28-day Cycle)
```
Days 6-10:   Follicular (Power phase) - IF 17h
Days 11-12:  Transition (Manifestation phase) - IF 13h ← NEW: Separate transition zone
Days 13-15:  Ovulation (Manifestation phase) - IF 13h ← NARROWER: Only 3 days
Days 16-19:  Early Luteal (Power phase) - IF 15h ← ADJUSTED: 4 days
Days 20-28:  Luteal (Nurture phase) - No fasting ← EXTENDED: 9 days
```

## Compilation Status
✅ All files compile without errors:
- [lib/utils/cycle_utils.dart](lib/utils/cycle_utils.dart): No issues found
- [lib/services/supabase_cycle_manager.dart](lib/services/supabase_cycle_manager.dart): No issues found
- [lib/screens/dashboard_screen.dart](lib/screens/dashboard_screen.dart): Syntax verified
- [lib/screens/lifestyle_syncing_screen.dart](lib/screens/lifestyle_syncing_screen.dart): Syntax verified
- [lib/screens/calendar_screen.dart](lib/screens/calendar_screen.dart): Syntax verified

## Testing Recommendations
1. **Unit Tests**: Verify getCyclePhase() returns correct phase for each day (1-28)
2. **Dashboard**: Check phase ranges display correctly in dashboard UI
3. **Calendar**: Verify phase colors and upcoming highlights show correct days
4. **Lifecycle**: Test with different cycle lengths (26, 28, 32, 35 days)
5. **Edge Cases**: Test phase transitions on boundary days

## Next Steps
- Update PHASE_QUICK_REFERENCE.md with new day-by-day tables
- Run full test suite to validate logic
- Test app UI on all screens to verify display accuracy
