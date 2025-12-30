# Single Source of Truth - Implementation Summary

## What Was Done

Created a **single authoritative source** for all cycle phase predictions in the Cycle Sync MVP.

### Key Achievement ✅

Instead of having phase guidance scattered across multiple files with hardcoded switch statements, everything now flows from ONE place:

```
Phase Model (lib/models/phase.dart)
        ↓
All guidance functions automatically use it
        ↓
All screens display consistent data
        ↓
One place to update = everywhere updates
```

## Files Updated

### 1. **Phase Model - Single Source of Truth** 
📁 `lib/models/phase.dart`

**Changes:**
- ✅ Added `hormonalBasis` field (hormonal state)
- ✅ Added `workoutPhase` field (Power/Manifestation/Nurture)
- ✅ Added `nutritionApproach` field (Ketobiotic/Hormone Feasting)
- ✅ Added `workoutEmoji` field
- ✅ Added `nutritionEmoji` field
- ✅ Updated all 5 phases with complete data:
  - Menstrual
  - Follicular
  - Ovulation
  - Early Luteal
  - Luteal

**Result:** Phase model now contains ALL guidance information in one place

### 2. **Cycle Utils - Removed Hardcoded Logic**
📁 `lib/utils/cycle_utils.dart`

**Changes:**
- ✅ Added import: `import '../models/phase.dart' as phase_model;`
- ✅ Removed all hardcoded switch statements from guidance functions
- ✅ Updated `getHormonalBasis()` to pull from Phase model
- ✅ Updated `getWorkoutPhase()` to pull from Phase model
- ✅ Updated `getNutritionGuidance()` to pull from Phase model
- ✅ Added NEW `getFastingPhase()` function pulling from Phase model
- ✅ Updated `getPhaseGuidance()` to return all 5 guidance types
- ✅ Updated `getWorkoutPhaseEmoji()` to pull from Phase model
- ✅ Updated `getNutritionPhaseEmoji()` to pull from Phase model

**Result:** All guidance functions now pull from single Phase model source

### 3. **Architecture Documentation**
📁 `MVP_ARCHITECTURE.md`

**Changes:**
- ✅ Added documentation of Phase Model as single source of truth
- ✅ Referenced new `PHASE_PREDICTIONS_GUIDE.md`
- ✅ Explained single point of update

### 4. **Comprehensive Guidance System Documentation**
📁 `PHASE_PREDICTIONS_GUIDE.md` (NEW)

**Content:**
- ✅ Complete architecture overview
- ✅ Phase model structure explanation
- ✅ How guidance functions work
- ✅ Phase calculation flow
- ✅ Phase boundaries (5-phase model)
- ✅ All guidance types included
- ✅ Where each type is used
- ✅ Future extension guide
- ✅ Testing strategy

## Data Structure

### Before: Multiple Switch Statements (Scattered)
```dart
// cycle_utils.dart
String getHormonalBasis(String phase) {
  switch (phase) {
    case 'Menstrual':
      return 'Estrogen & progesterone low';
    // ... 10+ cases
  }
}

String getWorkoutPhase(String phase) {
  switch (phase) {
    case 'Menstrual':
      return 'Power Phase';
    // ... 10+ cases
  }
}

// Similar hardcoded functions for nutrition, fasting, emojis
// (Data duplicated, hard to maintain)
```

### After: Single Phase Model (Centralized)
```dart
// phase.dart - SINGLE SOURCE OF TRUTH
class CyclePhases {
  static const List<Phase> phases = [
    Phase(
      name: 'Menstrual',
      emoji: '🩸',
      description: 'Rest & Restore',
      hormonalBasis: 'Estrogen & progesterone low',      // ← HERE
      workoutPhase: 'Power Phase',                       // ← HERE
      nutritionApproach: 'Ketobiotic',                   // ← HERE
      fastingType: 'Power Fasting',                      // ← HERE
      workoutEmoji: '💪',                                // ← HERE
      nutritionEmoji: '🥗',                              // ← HERE
      // ... all data in one place
    ),
    // ... other 4 phases with complete data
  ];
}

// cycle_utils.dart - PULLS FROM MODEL
String getHormonalBasis(String phase) {
  final phaseData = CyclePhases.findPhaseByName(phase);
  return phaseData?.hormonalBasis ?? 'Unknown';  // ← Automatic update
}
```

## How to Update Phase Data

### Single Point Update (No Duplication)

**To update Menstrual phase guidance:**

1. Open `lib/models/phase.dart`
2. Find the Menstrual phase in `CyclePhases.phases`
3. Update fields:
   ```dart
   Phase(
     name: 'Menstrual',
     hormonalBasis: 'Updated basis...',  // ← Update here
     workoutPhase: 'Updated phase...',   // ← Update here
     nutritionApproach: 'Updated...',    // ← Update here
     // etc.
   )
   ```
4. Save file
5. All screens automatically show updated data ✅
   - Dashboard
   - Calendar
   - Day Details Modal
   - Fasting Suggestions
   - Nutrition Suggestions
   - Fitness Suggestions

**That's it!** No more hunting through multiple files for hardcoded switch statements.

## All Predictions Included

✅ **Hormonal Phases**
- Menstrual, Follicular, Ovulation, Early Luteal, Luteal

✅ **Hormonal States** (from Phase model)
- Estrogen/progesterone levels at each phase

✅ **Workout Phases** (Dr. Mindy Pelz)
- Power Phase (high intensity)
- Manifestation Phase (peak energy)
- Nurture Phase (restorative)

✅ **Nutrition Approaches** (Dr. Indy Kensington)
- Ketobiotic (lower carb, lighter meals)
- Hormone Feasting (higher carb, nutrient-dense)

✅ **Fasting Recommendations**
- Power Fasting (16-20 hours)
- Manifestation Fasting (24-36 hours)
- Nurture Fasting (eat normally)

✅ **Supporting Data**
- Phase emoji
- Phase description
- Phase characteristics
- Emoji for each guidance type

✅ **Additional Predictions** (from cycle_utils)
- Next period date
- Ovulation date
- Fertile window (6 days)
- Days until phase change
- Next phase name

## Files Still Using Phase Model Correctly

All these files automatically benefit from the single source of truth:

- ✅ `lib/screens/dashboard_screen.dart` - Shows today's guidance
- ✅ `lib/screens/calendar_screen.dart` - Shows phase for each day + guidance
- ✅ `lib/screens/profile_screen.dart` - Shows cycle configuration
- ✅ `lib/screens/fasting_suggestions_screen.dart` - Uses fasting recommendations
- ✅ `lib/screens/nutrition_suggestions_screen.dart` - Uses nutrition guidance
- ✅ `lib/screens/fitness_suggestions_screen.dart` - Uses workout guidance
- ✅ `lib/screens/lifestyle_syncing_screen.dart` - Uses all guidance

## Verification Checklist

- ✅ No compilation errors
- ✅ All 5 phases have complete data
- ✅ Phase model is single source of truth
- ✅ All guidance functions pull from Phase model
- ✅ No hardcoded switch statements for guidance
- ✅ Dashboard displays all guidance types
- ✅ Calendar displays phase + guidance
- ✅ Day details modal complete
- ✅ Future expansion guide documented
- ✅ Architecture documentation updated

## Benefits of This Architecture

1. **Maintainability**: Update one place, everywhere updates
2. **Consistency**: No duplicate data = no conflicts
3. **Scalability**: Easy to add new guidance types
4. **Testing**: Single model to test
5. **Code Quality**: No scattered logic
6. **Performance**: No duplicated data structures
7. **Future-Proof**: Ready for new guidance frameworks

## Future Extensions

To add new guidance types (e.g., "Sleep Optimization"):

1. Add field to Phase class: `final String sleepGuidance;`
2. Add to all 5 phases in CyclePhases
3. Create getter: `String getSleepGuidance(String phase) { ... }`
4. Use in screens

**Total changes needed: 3 places** (class, data, function)  
**Previously would need: 10+ places** (multiple switch statements)

## Single Source of Truth Achieved ✅

All cycle phase predictions now come from one authoritative model:

```
┌─────────────────────────────────────┐
│  Phase Model (lib/models/phase.dart) │  ← SINGLE SOURCE OF TRUTH
│                                     │
│  Contains:                          │
│  • Hormonal basis                   │
│  • Workout phases                   │
│  • Nutrition approaches             │
│  • Fasting recommendations          │
│  • Emojis & descriptions            │
└─────────────────────────────────────┘
          ↓ (Reference)
┌─────────────────────────────────────┐
│  Cycle Utils (guidance functions)    │
│  All pull from Phase model           │
└─────────────────────────────────────┘
          ↓ (Use)
┌─────────────────────────────────────┐
│  All Screens                         │
│  Dashboard, Calendar, Suggestions    │
│  Auto-update when model changes      │
└─────────────────────────────────────┘
```

---

**Status:** ✅ COMPLETE  
**Date:** December 30, 2025  
**Version:** 1.0 - Single Source of Truth Architecture
