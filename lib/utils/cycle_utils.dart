import 'package:flutter/material.dart';
import '../models/phase.dart' as phase_model;

/// ============================================================================
/// ADAPTIVE PHASE CALCULATION (Text-Based, 5-Phase Model)
/// ============================================================================
/// 
/// Source of Truth: User inputs
/// 1. Start date = Day 1 (first day of menstruation)
/// 2. Cycle length (default 28, user adjustable)
/// 3. Luteal length (default 14, fixed reference)
/// 4. Menstrual length (default 5, user adjustable)
/// 
/// Phase Calculation:
/// - Ovulation Day = Cycle Length – Luteal Length (ANCHOR)
/// 
/// Phases (5-phase model):
/// 1. Menstrual: Day 1 → menstrualLength
/// 2. Follicular: Day (menstrualLength + 1) → (OvulationDay - 1)
/// 3. Ovulation: Day OvulationDay (optionally ±1 for lifestyle guidance)
/// 4. Early Luteal: Day (OvulationDay + 1) → (OvulationDay + 5)
/// 5. Late Luteal: Day (OvulationDay + 6) → Cycle Length
/// ============================================================================

const int DEFAULT_LUTEAL_LENGTH = 14;
const int DEFAULT_MENSTRUAL_LENGTH = 5;

/// Calculate the ovulation day within a cycle.
/// 
/// Formula: Ovulation Day = Cycle Length – Luteal Length
/// 
/// Parameters:
/// - `cycleLength`: Total cycle length in days
/// - `lutealLength`: Fixed luteal phase length (default 14)
/// 
/// Returns the day of cycle when ovulation occurs (1-based).
int getOvulationDay(int cycleLength, {int lutealLength = DEFAULT_LUTEAL_LENGTH}) {
  return cycleLength - lutealLength;
}

/// Determines the current cycle phase using 5-Phase Adaptive Calculation (DAY-BASED).
/// 
/// ============================================================================
/// SINGLE SOURCE OF TRUTH: Day-Based Boundaries (Refined)
/// ============================================================================
/// This function uses EXACT day boundaries, not percentages. This ensures
/// perfect adaptation to any cycle length and menstrual length.
/// 
/// ANCHOR POINTS:
/// - Day 1 = first day of menstruation (user input)
/// - Ovulation Day = Cycle Length – Luteal Length (default 14)
/// 
/// PHASE MAPPING (Bulletproof Boundaries):
/// 1. Menstrual:     Day 1 → menstrualLength
/// 2. Follicular:    Day (menstrualLength + 1) → (ovulationDay - 2)
/// 3. Ovulation:     Day (ovulationDay - 2) → (ovulationDay + 2) [5-day manifestation window]
/// 4. Early Luteal:  Day (ovulationDay + 3) → (ovulationDay + 7)
/// 5. Late Luteal:   Day (ovulationDay + 8) → cycleLength
/// 
/// EXAMPLE: 28-day cycle, menstrualLength=5
/// ovulationDay = 28 - 14 = 14
/// - Menstrual:     Days 1-5
/// - Follicular:    Days 6-12 (OD-2)
/// - Ovulation:     Days 13-15 (OD-1 to OD+1)
/// - Early Luteal:  Days 16-19 (OD+2 to OD+5)
/// - Late Luteal:   Days 20-28 (OD+6 to end)
/// 
/// Parameters:
/// - `lastPeriodStart`: The start date of the last menstrual period (Day 1 anchor)
/// - `cycleLength`: Total cycle length in days
/// - `today`: The date to calculate phase for
/// - `menstrualLength`: Menstrual phase length in days (default 5)
/// - `lutealLength`: Luteal phase length in days (default 14)
/// 
/// Returns the current cycle phase as a string.
/// Uses the detailed phase table with adjusted boundaries:
/// 
/// Day 1–(ML-1):              Menstrual, Power phase, IF 13h
/// Day ML:                    Menstrual, Power phase, IF 15h
/// Day (ML+1)–(ML+5):         Follicular, Power phase, IF 17h
/// Day (ML+6)–(OD-2):         Follicular, Manifestation, IF 13h
/// Day (OD-1)–(OD+1):         Ovulation, Manifestation, IF 13h
/// Day (OD+2)–(OD+5):         Early Luteal, Power phase, IF 15h
/// Day (OD+6)–CycleLength:    Luteal, Nurture phase, No IF
String getCyclePhase(
  DateTime lastPeriodStart,
  int cycleLength,
  DateTime today, {
  int menstrualLength = DEFAULT_MENSTRUAL_LENGTH,
  int lutealLength = DEFAULT_LUTEAL_LENGTH,
}) {
  // Calculate which day of the cycle we're on (1-based)
  // Day 1 is the first day of menstruation (ANCHOR 1)
  int dayOfCycle = (today.difference(lastPeriodStart).inDays % cycleLength) + 1;

  // ANCHOR 2: Calculate ovulation day using fixed luteal length
  int ovulationDay = getOvulationDay(cycleLength, lutealLength: lutealLength);

  // Phase 1: MENSTRUAL split into two parts based on detailed table:
  // Part A: Day 1 → (ML-1) - Menstrual (Days 1 to ML-1), IF 13h, Power phase
  // Part B: Day ML - Menstrual (Day ML), IF 15h, Power phase
  if (dayOfCycle >= 1 && dayOfCycle <= menstrualLength) {
    if (dayOfCycle < menstrualLength) {
      return 'Menstrual (Days 1 to ML-1)';
    } else {
      return 'Menstrual (Day ML)';
    }
  }

  // Phase 2: FOLLICULAR (Day (menstrualLength + 1) → (ovulationDay - 2))
  // Split into two parts based on detailed table:
  // Part A: Day (ML+1) → (ML+5) - Power phase follicular (Early Follicular)
  // Part B: Day (ML+6) → (OD-2) - Manifestation phase follicular (Late Follicular)
  if (dayOfCycle > menstrualLength && dayOfCycle < (ovulationDay - 1)) {
    // Determine if early or late follicular
    if (dayOfCycle <= (menstrualLength + 5)) {
      return 'Follicular (Early)';
    } else {
      return 'Follicular (Late)';
    }
  }

  // Phase 3: OVULATION (Day (ovulationDay - 1) → (ovulationDay + 1))
  // 3-day core ovulation window (OD-1, OD, OD+1)
  if (dayOfCycle >= (ovulationDay - 1) && dayOfCycle <= (ovulationDay + 1)) {
    return 'Ovulation';
  }

  // Phase 4: EARLY LUTEAL (Day (ovulationDay + 2) → (ovulationDay + 5))
  if (dayOfCycle >= (ovulationDay + 2) && dayOfCycle <= (ovulationDay + 5)) {
    return 'Early Luteal';
  }

  // Phase 5: LATE LUTEAL (Day (ovulationDay + 6) → cycleLength)
  if (dayOfCycle >= (ovulationDay + 6)) {
    return 'Luteal (Late)';
  }

  // Fallback (should not reach here)
  return 'Luteal (Late)';
}

/// Checks if a day is within the fertile window (conception window).
/// 
/// Fertile window: 5 days before ovulation + ovulation day (6-day window total)
/// 
/// Parameters:
/// - `lastPeriodStart`: The start date of the last menstrual period.
/// - `cycleLength`: Average cycle length in days.
/// - `checkDay`: The day to check.
/// - `lutealLength`: Luteal phase length for ovulation calculation (default 14)
/// 
/// Returns true if the day is within the fertile window.
bool isFertileWindow(
  DateTime lastPeriodStart,
  int cycleLength,
  DateTime checkDay, {
  int lutealLength = DEFAULT_LUTEAL_LENGTH,
}) {
  // Calculate which day of the cycle we're on (1-based)
  int dayOfCycle = (checkDay.difference(lastPeriodStart).inDays % cycleLength) + 1;

  // Calculate ovulation day using fixed luteal length
  int ovulationDay = getOvulationDay(cycleLength, lutealLength: lutealLength);
  
  // Fertile window: 5 days before ovulation + ovulation day (6 days total)
  int fertileStart = ovulationDay - 5;
  int fertileEnd = ovulationDay;

  return dayOfCycle >= fertileStart && dayOfCycle <= fertileEnd;
}

/// Returns the emoji representation of a cycle phase.
String getPhaseEmoji(String phase) {
  switch (phase) {
    case 'Menstrual (Days 1 to ML-1)':
    case 'Menstrual (Day ML)':
      return '🩸';
    case 'Follicular (Early)':
    case 'Follicular (Late)':
      return '🌱';
    case 'Ovulation':
      return '✨';
    case 'Early Luteal':
      return '🌙';
    case 'Luteal (Late)':
      return '🌙';
    default:
      return '💫';
  }
}
/// Returns the faded color for a given cycle phase.
/// Colors are intentionally muted so they can be enhanced when data is logged.

Color getPhaseColor(String phase) {
  switch (phase) {
    case 'Menstrual (Days 1 to ML-1)':
    case 'Menstrual (Day ML)':
      return const Color(0xFFEDD8D8); // Faded Pink
    case 'Follicular (Early)':
    case 'Follicular (Late)':
      return const Color(0xFFD8EFF8); // Faded Sky Blue
    case 'Ovulation':
      return const Color(0xFFEDD8D8); // Faded Pink
    case 'Early Luteal':
      return const Color(0xFFE8D8F8); // Faded Lavender
    case 'Luteal (Late)':
      return const Color(0xFFE8D8F8); // Faded Lavender
    default:
      return Colors.grey.shade100;
  }
}

/// Returns phase-specific energy/mood description.
String getPhaseDescription(String phase) {
  switch (phase) {
    case 'Menstrual (Days 1 to ML-1)':
    case 'Menstrual (Day ML)':
    case 'Menstrual':
      return 'Rest & Restore';
    case 'Follicular (Early)':
      return 'Rising Energy';
    case 'Follicular (Late)':
      return 'Peak Confidence';
    case 'Ovulation':
      return 'Peak Energy';
    case 'Early Luteal':
      return 'Building Energy';
    case 'Luteal (Late)':
      return 'Inward Focus';
    default:
      return 'Cycle Tracking';
  }
}
/// ============================================================================
/// PREDICTION MODULE - Key Cycle Predictions
/// ============================================================================

/// Get the next period start date.
/// 
/// Parameters:
/// - `lastPeriodStart`: The start date of the last menstrual period.
/// - `cycleLength`: Average cycle length in days.
/// 
/// Returns the predicted date of the next period.
DateTime getNextPeriodDate(DateTime lastPeriodStart, int cycleLength) {
  return lastPeriodStart.add(Duration(days: cycleLength));
}

/// Get the ovulation date for the current cycle.
/// 
/// Parameters:
/// - `lastPeriodStart`: The start date of the last menstrual period.
/// - `cycleLength`: Average cycle length in days.
/// - `lutealLength`: Luteal phase length for calculation (default 14)
/// 
/// Returns the predicted ovulation date.
DateTime getOvulationDate(
  DateTime lastPeriodStart,
  int cycleLength, {
  int lutealLength = DEFAULT_LUTEAL_LENGTH,
}) {
  int ovulationDay = getOvulationDay(cycleLength, lutealLength: lutealLength);
  return lastPeriodStart.add(Duration(days: ovulationDay - 1));
}

/// Get the fertile window dates.
/// 
/// Parameters:
/// - `lastPeriodStart`: The start date of the last menstrual period.
/// - `cycleLength`: Average cycle length in days.
/// - `lutealLength`: Luteal phase length for calculation (default 14)
/// 
/// Returns a map with 'start' and 'end' dates for the fertile window.
Map<String, DateTime> getFertileWindowDates(
  DateTime lastPeriodStart,
  int cycleLength, {
  int lutealLength = DEFAULT_LUTEAL_LENGTH,
}) {
  int ovulationDay = getOvulationDay(cycleLength, lutealLength: lutealLength);
  DateTime fertileStart = lastPeriodStart.add(Duration(days: ovulationDay - 6)); // 5 days before ovulation
  DateTime fertileEnd = lastPeriodStart.add(Duration(days: ovulationDay)); // Ovulation day

  return {
    'start': fertileStart,
    'end': fertileEnd,
  };
}

/// Get days until next phase.
/// 
/// Parameters:
/// - `lastPeriodStart`: The start date of the last menstrual period.
/// - `cycleLength`: Average cycle length in days.
/// - `periodLength`: Duration of menstrual period in days.
/// - `today`: Current date to calculate from.
/// - `lutealLength`: Luteal phase length for calculation (default 14)
/// 
/// Returns number of days remaining in the current phase.
int getDaysUntilNextPhase(
  DateTime lastPeriodStart,
  int cycleLength,
  int periodLength,
  DateTime today, {
  int lutealLength = DEFAULT_LUTEAL_LENGTH,
}) {
  int dayOfCycle = (today.difference(lastPeriodStart).inDays % cycleLength) + 1;
  int ovulationDay = getOvulationDay(cycleLength, lutealLength: lutealLength);

  // Phase boundaries from new adaptive table:
  // - Menstrual: Day 1 → periodLength
  // - Follicular: Day (periodLength + 1) → (ovulationDay - 2)
  // - Ovulation: Day (ovulationDay - 1) → (ovulationDay + 1)
  // - Early Luteal: Day (ovulationDay + 2) → (ovulationDay + 5)
  // - Late Luteal: Day (ovulationDay + 6) → cycleLength
  
  if (dayOfCycle <= periodLength) {
    return periodLength - dayOfCycle + 1; // Days left in menstrual
  } else if (dayOfCycle < (ovulationDay - 1)) {
    return (ovulationDay - 1) - dayOfCycle + 1; // Days until ovulation
  } else if (dayOfCycle <= (ovulationDay + 1)) {
    return (ovulationDay + 1) - dayOfCycle + 1; // Days left in ovulation
  } else if (dayOfCycle <= (ovulationDay + 5)) {
    return (ovulationDay + 5) - dayOfCycle + 1; // Days left in early luteal
  } else {
    return cycleLength - dayOfCycle + 1; // Days until next period
  }
}

/// Get the next phase after the current one.
/// 
/// Parameters:
/// - `currentPhase`: The current cycle phase.
/// 
/// Returns the name of the next phase.
String getNextPhase(String currentPhase) {
  switch (currentPhase) {
    case 'Menstrual (Days 1 to ML-1)':
      return 'Menstrual (Day ML)';
    case 'Menstrual (Day ML)':
      return 'Follicular (Early)';
    case 'Follicular (Early)':
      return 'Follicular (Late)';
    case 'Follicular (Late)':
      return 'Ovulation';
    case 'Ovulation':
      return 'Early Luteal';
    case 'Early Luteal':
      return 'Luteal (Late)';
    case 'Luteal (Late)':
      return 'Menstrual (Days 1 to ML-1)';
    case 'Menstrual':
      return 'Follicular (Early)';
    default:
      return 'Unknown';
  }
}

/// Calculate average cycle length from previous cycles.
/// 
/// Parameters:
/// - `previousCycleLengths`: List of previous cycle lengths in days.
/// 
/// Returns average cycle length.
int calculateAverageCycleLength(List<int> previousCycleLengths) {
  if (previousCycleLengths.isEmpty) return 0;
  
  int total = previousCycleLengths.fold(0, (sum, length) => sum + length);
  return total ~/ previousCycleLengths.length;
}

/// Calculate cycle variance (standard deviation indicator).
/// 
/// Parameters:
/// - `previousCycleLengths`: List of previous cycle lengths.
/// 
/// Returns variance in days from average.
int calculateCycleVariance(List<int> previousCycleLengths) {
  if (previousCycleLengths.isEmpty) return 0;
  
  int average = calculateAverageCycleLength(previousCycleLengths);
  int maxDiff = 0;
  
  for (int length in previousCycleLengths) {
    int diff = (length - average).abs();
    if (diff > maxDiff) maxDiff = diff;
  }
  
  return maxDiff;
}

/// Check if cycles are regular.
/// 
/// Returns true if variance is within ±2 days of average.
bool areCyclesRegular(List<int> previousCycleLengths) {
  return calculateCycleVariance(previousCycleLengths) <= 2;
}

/// ============================================================================
/// GUIDANCE SYSTEM - Single Source of Truth from Phase Model
/// ============================================================================
/// All guidance (hormonal, workout, nutrition, fasting) is derived from the
/// Phase model in lib/models/phase.dart which is the authoritative source.

/// Get the hormonal state for the current phase.
String getHormonalState(String phase) {
  final phaseData = phase_model.CyclePhases.findPhaseByName(phase);
  return phaseData?.hormonalState ?? 'Unknown hormonal state';
}

/// Get the lifestyle phase (Power, Manifestation, or Nurture).
String getLifestylePhase(String phase) {
  final phaseData = phase_model.CyclePhases.findPhaseByName(phase);
  return phaseData?.lifestylePhase ?? 'Balanced';
}

/// Get the workout type recommendation for the phase.
String getWorkoutType(String phase) {
  final phaseData = phase_model.CyclePhases.findPhaseByName(phase);
  return phaseData?.workoutType ?? 'Moderate exercise';
}

/// Get the diet type recommendation for the phase.
String getDietType(String phase) {
  final phaseData = phase_model.CyclePhases.findPhaseByName(phase);
  return phaseData?.dietType ?? 'Balanced nutrition';
}

/// Get the fasting duration recommendation for the phase.
String getFastingDuration(String phase) {
  final phaseData = phase_model.CyclePhases.findPhaseByName(phase);
  return phaseData?.fastingDuration ?? 'IF 16h';
}

/// Get detailed phase-specific guidance notes.
String getGuidanceNotes(String phase) {
  final phaseData = phase_model.CyclePhases.findPhaseByName(phase);
  return phaseData?.guidanceNotes ?? 'No specific recommendations';
}

/// Get detailed phase-specific recommendations as a map.
Map<String, String> getPhaseGuidance(String phase) {
  final phaseData = phase_model.CyclePhases.findPhaseByName(phase);
  if (phaseData == null) {
    return {
      'phase': phase,
      'lifestyle': 'Balanced',
      'hormonal': 'Unknown',
      'workout': 'Moderate',
      'nutrition': 'Balanced',
      'fasting': 'IF 16h',
      'notes': 'No information available',
    };
  }
  
  return {
    'phase': phaseData.name,
    'lifestyle': phaseData.lifestylePhase,
    'hormonal': phaseData.hormonalState,
    'workout': phaseData.workoutType,
    'nutrition': phaseData.dietType,
    'fasting': phaseData.fastingDuration,
    'notes': phaseData.guidanceNotes,
  };
}

/// Get emoji for workout type.
String getWorkoutPhaseEmoji(String workoutType) {
  final phaseData = phase_model.CyclePhases.findPhaseByWorkoutType(workoutType);
  if (phaseData != null) {
    return phaseData.workoutEmoji;
  }
  
  // Fallback for common workout types
  switch (workoutType) {
    case 'Power':
    case 'High-intensity':
      return '💪';
    case 'Manifestation':
    case 'Moderate':
      return '✨';
    case 'Nurture':
    case 'Low-intensity':
      return '🌸';
    default:
      return '🏋️';
  }
}

/// Get emoji for nutrition approach.
String getNutritionPhaseEmoji(String nutritionType) {
  final phaseData = phase_model.CyclePhases.findPhaseByDietType(nutritionType);
  if (phaseData != null) {
    return phaseData.nutritionEmoji;
  }
  
  // Fallback for common nutrition types
  switch (nutritionType) {
    case 'Ketobiotic':
    case 'Low-carb':
      return '🥗';
    case 'Hormone Feasting':
    case 'High-carb':
      return '🍲';
    default:
      return '🍽️';
  }
}
