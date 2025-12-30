/// Data model for menstrual cycle phases based on Dr. Mindy Pelz's cycle syncing framework.
/// 
/// THIS IS THE SINGLE SOURCE OF TRUTH for all cycle phase predictions:
/// - Hormonal phases (from cycle_utils.getCyclePhase)
/// - Workout phases (Power, Manifestation, Nurture)
/// - Nutrition approaches (Ketobiotic, Hormone Feasting)
/// - Fasting recommendations
/// 
/// IMPORTANT: Phase boundaries are defined by DAY-BASED LOGIC ONLY in getCyclePhase().
/// Do NOT use percentages for phase predictions - they are inaccurate and cause misalignment.
/// Use getCyclePhase() function with actual calendar dates.
class Phase {
  final String name;
  final String emoji;
  final String description;
  final String dietName;
  final String workoutName;
  final String fastingType;
  final String hormonalBasis; // Hormonal state description
  final String workoutPhase; // Dr. Mindy's workout phase (Power/Manifestation/Nurture)
  final String nutritionApproach; // Dr. Indy's nutrition approach (Ketobiotic/Hormone Feasting)
  final String workoutEmoji;
  final String nutritionEmoji;
  final String fastingDetails; // Detailed IF recommendations by day
  
  // NOTE: Percentages removed. Use getCyclePhase() with actual dates for accurate phase prediction.

  const Phase({
    required this.name,
    required this.emoji,
    required this.description,
    required this.dietName,
    required this.workoutName,
    required this.fastingType,
    required this.hormonalBasis,
    required this.workoutPhase,
    required this.nutritionApproach,
    required this.workoutEmoji,
    required this.nutritionEmoji,
    required this.fastingDetails,
  });

  /// Get next phase in the cycle.
  String? get nextPhase {
    final phaseIndex = CyclePhases.phases.indexOf(this);
    if (phaseIndex >= 0 && phaseIndex < CyclePhases.phases.length - 1) {
      return CyclePhases.phases[phaseIndex + 1].name;
    }
    return 'Menstrual'; // Loop back to menstrual phase
  }
}

/// Static list of phases based on Dr. Mindy Pelz's cycle syncing framework.
/// THIS IS THE SINGLE SOURCE OF TRUTH for all phase predictions.
/// 
/// PHASE BOUNDARIES (Day-Based, from getCyclePhase()):
/// - Menstrual:    Day 1 → menstrualLength
/// - Follicular:   Day (menstrualLength + 1) → (ovulationDay - 2)
/// - Ovulation:    Day (ovulationDay - 2) → (ovulationDay + 2) [5-day Manifestation window]
/// UPDATED PHASE BOUNDARIES (NEW LOGIC):
/// Using day-based boundaries with fixed 14-day luteal reference.
/// ovulationDay (OD) = cycleLength - 14
/// 
/// - Menstrual:    Day 1 → menstrualLength
/// - Follicular:   Day (menstrualLength + 1) → (ovulationDay - 2)
/// - Ovulation:    Day (ovulationDay - 1) → (ovulationDay + 1)
/// - Early Luteal: Day (ovulationDay + 2) → (ovulationDay + 5)
/// - Late Luteal:  Day (ovulationDay + 6) → cycleLength
/// 
/// Example (28-day cycle, menstrualLength=5, ovulationDay=14):
/// - Menstrual:    Days 1-5
/// - Follicular:   Days 6-12
/// - Ovulation:    Days 13-15 (3-day peak window: OD-1 to OD+1)
/// - Early Luteal: Days 16-19
/// - Late Luteal:  Days 20-28
/// 
/// ⚠️ DO NOT USE PERCENTAGES FOR PHASE PREDICTION!
/// Use getCyclePhase(lastPeriodStart, cycleLength, today, menstrualLength) instead.
class CyclePhases {
  static const List<Phase> phases = [
    Phase(
      name: 'Menstrual',
      emoji: '🩸',
      description: 'Rest & Restore',
      dietName: 'Restorative Nutrition',
      workoutName: 'Low-Impact Training',
      fastingType: 'Power Fasting',
      hormonalBasis: 'Estrogen low, Progesterone declining',
      workoutPhase: 'Power Phase',
      nutritionApproach: 'Ketobiotic',
      workoutEmoji: '💪',
      nutritionEmoji: '🥗',
      fastingDetails: 'IF 13-15h',
    ),
    Phase(
      name: 'Follicular',
      emoji: '🌱',
      description: 'High Energy Day',
      dietName: 'Energizing Nutrition',
      workoutName: 'Mid-Impact Training',
      fastingType: 'Power Fasting',
      hormonalBasis: 'Estrogen rising, FSH increasing',
      workoutPhase: 'Power Phase (continued)',
      nutritionApproach: 'Ketobiotic',
      workoutEmoji: '💪',
      nutritionEmoji: '🥗',
      fastingDetails: 'IF 17h',
    ),
    Phase(
      name: 'Ovulation',
      emoji: '✨',
      description: 'Peak Energy',
      dietName: 'Light & Fresh',
      workoutName: 'Strength Training',
      fastingType: 'Manifestation Fasting',
      hormonalBasis: 'Estrogen peak, LH surge',
      workoutPhase: 'Manifestation Phase',
      nutritionApproach: 'Hormone Feasting',
      workoutEmoji: '✨',
      nutritionEmoji: '🍲',
      fastingDetails: 'IF 13h',
    ),
    Phase(
      name: 'Early Luteal',
      emoji: '🌙',
      description: 'Building Energy',
      dietName: 'Balanced Nutrition',
      workoutName: 'Mid-Impact Training',
      fastingType: 'Power Fasting',
      hormonalBasis: 'Progesterone rising, estrogen stable',
      workoutPhase: 'Power Phase (again)',
      nutritionApproach: 'Ketobiotic',
      workoutEmoji: '💪',
      nutritionEmoji: '🥗',
      fastingDetails: 'IF 15h',
    ),
    Phase(
      name: 'Luteal',
      emoji: '🌙',
      description: 'Inward Focus',
      dietName: 'Calming Nutrition',
      workoutName: 'Mid- to Low-Impact Training',
      fastingType: 'Nurture Fasting',
      hormonalBasis: 'Progesterone dominant, metabolism elevated',
      workoutPhase: 'Nurture Phase',
      nutritionApproach: 'Hormone Feasting',
      workoutEmoji: '🌸',
      nutritionEmoji: '🍲',
      fastingDetails: 'No IF - eat regularly',
    ),
  ];

  /// Find phase by name.
  static Phase? findPhaseByName(String name) {
    try {
      return phases.firstWhere((phase) => phase.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Find phase for a given cycle day.
  /// ⚠️ DEPRECATED: Use getCyclePhase() instead for accurate predictions!
  /// This method is no longer recommended due to percentage-based calculations.
  @Deprecated('Use getCyclePhase() from cycle_utils.dart instead')
  static Phase? findPhaseForDay(int dayOfCycle, int cycleLength) {
    // Not implemented - use getCyclePhase() instead
    return null;
  }

  /// Get all phase day ranges for a specific cycle length.
  /// ⚠️ DEPRECATED: Percentages should not be used for phase boundaries.
  /// Use getCyclePhase() with actual dates instead.
  @Deprecated('Use getCyclePhase() from cycle_utils.dart instead')
  static Map<String, String> getAllPhaseRanges(int cycleLength) {
    return {}; // Not implemented - use getCyclePhase() instead
  }
}
