# Phase Predictions - Single Source of Truth

## Overview

All cycle phase predictions in the Cycle Sync MVP are derived from a **single authoritative source**: the `Phase` model in `lib/models/phase.dart`.

This includes:
- ✅ Hormonal phases (Menstrual, Follicular, Ovulation, Early Luteal, Luteal)
- ✅ Hormonal basis (estrogen/progesterone states)
- ✅ Workout phases (Power Phase, Manifestation Phase, Nurture Phase) - Dr. Mindy Pelz
- ✅ Nutrition approaches (Ketobiotic, Hormone Feasting) - Dr. Indy Kensington
- ✅ Fasting recommendations (Power, Manifestation, Nurture)
- ✅ Emojis for each guidance type

## Architecture

```
PHASE MODEL (Single Source of Truth)
        ↓
lib/models/phase.dart
    ├── Phase class (data model)
    └── CyclePhases class (5-phase definition)
        ├── Menstrual
        ├── Follicular
        ├── Ovulation
        ├── Early Luteal
        └── Luteal
        
        ↓ (Referenced by)
        
CYCLE UTILS (calculation & guidance functions)
        ↓
lib/utils/cycle_utils.dart
    ├── getCyclePhase() - Calculates which phase user is in
    ├── getHormonalBasis() - Pulls from Phase.hormonalBasis
    ├── getWorkoutPhase() - Pulls from Phase.workoutPhase
    ├── getNutritionGuidance() - Pulls from Phase.nutritionApproach
    ├── getFastingPhase() - Pulls from Phase.fastingType
    ├── getPhaseGuidance() - Returns all guidance from single Phase model
    ├── getWorkoutPhaseEmoji() - Pulls from Phase.workoutEmoji
    └── getNutritionPhaseEmoji() - Pulls from Phase.nutritionEmoji
        
        ↓ (Used by)
        
USER INTERFACE
    ├── Dashboard Screen (displays today's guidance)
    ├── Calendar Screen (displays phase for each day)
    ├── Day Details Modal (displays complete guidance)
    ├── Fasting Suggestions (displays fasting options)
    ├── Nutrition Suggestions (displays meal options)
    └── Fitness Suggestions (displays workout options)
```

## Phase Model Structure

Each phase in `CyclePhases.phases` contains:

```dart
Phase(
  name: 'Menstrual',                          // Phase name
  emoji: '🩸',                                 // Phase emoji
  description: 'Rest & Restore',              // Phase description
  dietName: 'Restorative Nutrition',          // Traditional diet name
  workoutName: 'Low-Impact Training',         // Traditional workout name
  fastingType: 'Power Fasting',               // Fasting recommendation
  hormonalBasis: 'Estrogen low, Progesterone declining',  // Hormonal state
  workoutPhase: 'Power Phase',                // Dr. Mindy workout phase
  nutritionApproach: 'Ketobiotic',            // Dr. Indy nutrition approach
  workoutEmoji: '💪',                         // Workout emoji
  nutritionEmoji: '🥗',                       // Nutrition emoji
  fastingDetails: 'IF 13-15h',                // Core fasting recommendation
)
```

## How to Add/Update Phase Data

### Single Point of Update

When you need to change any phase guidance:

1. **ONLY edit** `lib/models/phase.dart` in the `CyclePhases.phases` array
2. All downstream functions will automatically use the updated data
3. No need to update multiple files

### Example: Update Menstrual Phase Guidance

```dart
// BEFORE:
Phase(
  name: 'Menstrual',
  hormonalBasis: 'Estrogen low, Progesterone declining',
  workoutPhase: 'Power Phase',
  // ... other fields
)

// AFTER:
Phase(
  name: 'Menstrual',
  hormonalBasis: 'Estrogen & progesterone low, FSH rising',  // Updated
  workoutPhase: 'Power Phase (Restorative)',                 // Updated
  // ... other fields
)
```

Then automatically:
- `getHormonalBasis('Menstrual')` returns the updated hormonal basis
- `getWorkoutPhase('Menstrual')` returns the updated workout phase
- Dashboard, Calendar, and all other screens show the new data
- No additional code changes needed ✅

## How Guidance Functions Work

All guidance functions in `cycle_utils.dart` now pull directly from the Phase model:

```dart
// Example: getHormonalBasis()
String getHormonalBasis(String phase) {
  final phaseData = CyclePhases.findPhaseByName(phase);
  return phaseData?.hormonalBasis ?? 'Unknown hormonal state';
}
```

**No hardcoded switch statements** - Pure single-source-of-truth design.

## Phase Calculation Flow

```
1. User's Last Period Start Date (INPUT)
2. User's Cycle Length (INPUT)
3. User's Menstrual Length (INPUT)
4. Current Date (INPUT)
        ↓
5. getCyclePhase() calculates which phase they're in
        ↓
6. Return phase name (e.g., "Ovulation")
        ↓
7. CyclePhases.findPhaseByName("Ovulation")
        ↓
8. Return Phase object with all guidance data
        ↓
9. UI displays hormonal basis, workout phase, nutrition approach, etc.
```

## Phase Boundaries (5-Phase Model)

**Adaptive to cycle length and menstrual length:**

```
Day 1: Menstruation starts
  ├─ Menstrual Phase: Days 1 → menstrualLength (default 5)
  │   └─ Hormonal: Estrogen low, Progesterone declining
  │   └─ Workout: Power Phase
  │   └─ Nutrition: Ketobiotic
  │   └─ Fasting: Power Fasting
  │
  ├─ Follicular Phase: (menstrualLength + 1) → (Ovulation Day - 1)
  │   └─ Hormonal: Estrogen rising, FSH increasing
  │   └─ Workout: Power Phase (continued)
  │   └─ Nutrition: Ketobiotic
  │   └─ Fasting: Power Fasting
  │
  ├─ Ovulation Phase: Ovulation Day → (Ovulation Day + 2)
  │   └─ Hormonal: Estrogen peak, LH surge
  │   └─ Workout: Manifestation Phase
  │   └─ Nutrition: Hormone Feasting
  │   └─ Fasting: Manifestation Fasting
  │
  ├─ Early Luteal Phase: (Ovulation Day + 3) → (Ovulation Day + 6)
  │   └─ Hormonal: Progesterone rising, estrogen stable
  │   └─ Workout: Power Phase (again)
  │   └─ Nutrition: Ketobiotic
  │   └─ Fasting: Power Fasting
  │
  └─ Luteal Phase: (Ovulation Day + 7) → Cycle Length
      └─ Hormonal: Progesterone dominant, metabolism elevated
      └─ Workout: Nurture Phase
      └─ Nutrition: Hormone Feasting
      └─ Fasting: Nurture Fasting
```

**Where:**
- Ovulation Day = Cycle Length - 14 (fixed luteal phase reference)
- Cycle Length = User input (default 28)
- Menstrual Length = User input (default 5)

## All Phase Predictions Included

### ✅ Hormonal Basis
- What hormones are dominant
- Hormone levels (rising, peak, declining)
- Phase-specific characteristics

### ✅ Workout Phase (Dr. Mindy Pelz)
- Power Phase: High intensity workouts (Menstrual, Follicular, Early Luteal)
- Manifestation Phase: Peak energy for goals (Ovulation)
- Nurture Phase: Restorative workouts (Luteal)

### ✅ Nutrition Approach (Dr. Indy Kensington)
- Ketobiotic: Lower carb, lighter meals (Menstrual, Follicular, Early Luteal)
- Hormone Feasting: Higher carb, nutrient-dense (Ovulation, Luteal)

### ✅ Fasting Recommendations
- Power Fasting: 16-20 hour fasts (Menstrual, Follicular, Early Luteal)
- Manifestation Fasting: 24-36 hour extended fasts (Ovulation)
- Nurture Fasting: Eat normally, no fasting (Luteal)

### ✅ Additional Predictions
- Next period start date
- Ovulation date
- Fertile window (6 days)
- Days until next phase
- Next phase name

## Where Each Guidance Type Is Used

### Dashboard Screen
- Shows today's hormonal state
- Shows today's workout phase + emoji
- Shows today's nutrition approach + emoji

### Calendar Screen
- **Fertile window**: Green border (6-day window)
- **Ovulation day**: Black outer ring
- **Day details modal:**
  - Phase summary with hormonal basis
  - Workout phase + emoji
  - Nutrition approach + emoji
  - Phase characteristics
  - Upcoming highlights (next phase, next period date)

### Fasting Suggestions Screen
- Displays fasting options based on phase's `fastingType`
- Linked from day details modal

### Nutrition Suggestions Screen
- Displays meal options based on phase's `dietName`
- Linked from day details modal

### Fitness Suggestions Screen
- Displays workout options based on phase's `workoutName`
- Linked from day details modal

## Future Extensions

To add new phase guidance types in the future:

1. Add new field to `Phase` class
   ```dart
   final String newGuidanceType;
   ```

2. Add to all phases in `CyclePhases.phases`
   ```dart
   newGuidanceType: 'some value',
   ```

3. Create getter function in `cycle_utils.dart`
   ```dart
   String getNewGuidance(String phase) {
     final phaseData = CyclePhases.findPhaseByName(phase);
     return phaseData?.newGuidanceType ?? 'default';
   }
   ```

4. Use in UI screens via the new function

**That's it!** No switch statements, no hardcoded values. Pure single-source-of-truth design.

## Testing Phase Data

To verify all phases have complete data:

```dart
// In test file
void testPhaseData() {
  for (final phase in CyclePhases.phases) {
    expect(phase.name, isNotEmpty);
    expect(phase.hormonalBasis, isNotEmpty);
    expect(phase.workoutPhase, isNotEmpty);
    expect(phase.nutritionApproach, isNotEmpty);
    expect(phase.fastingType, isNotEmpty);
    expect(phase.workoutEmoji, isNotEmpty);
    expect(phase.nutritionEmoji, isNotEmpty);
  }
}
```

## Related Files

- **Phase Model (Source of Truth):** `lib/models/phase.dart`
- **Calculation & Guidance Functions:** `lib/utils/cycle_utils.dart`
- **Dashboard Screen:** `lib/screens/dashboard_screen.dart`
- **Calendar Screen:** `lib/screens/calendar_screen.dart`
- **Profile Screen:** `lib/screens/profile_screen.dart`
- **Fasting Suggestions:** `lib/screens/fasting_suggestions_screen.dart`
- **Nutrition Suggestions:** `lib/screens/nutrition_suggestions_screen.dart`
- **Fitness Suggestions:** `lib/screens/fitness_suggestions_screen.dart`

---

**Last Updated:** December 30, 2025  
**Version:** 1.0 - Single Source of Truth Architecture
