/// Data model for menstrual cycle phases based on Dr. Mindy Pelz's cycle syncing framework.
class Phase {
  final String name;
  final String emoji;
  final String description;
  final String dietName;
  final String workoutName;
  final String fastingType;
  final double startPercentage; // Start of phase as % of cycle (0.0 - 1.0)
  final double endPercentage;   // End of phase as % of cycle (0.0 - 1.0)

  const Phase({
    required this.name,
    required this.emoji,
    required this.description,
    required this.dietName,
    required this.workoutName,
    required this.fastingType,
    required this.startPercentage,
    required this.endPercentage,
  });

  /// Get the day range for this phase (e.g., "Days 1–5").
  int get startDay => (startPercentage * 28).ceil();
  int get endDay => (endPercentage * 28).floor();

  /// Get next phase in the cycle.
  String? get nextPhase {
    final phaseIndex = CyclePhases.phases.indexOf(this);
    if (phaseIndex >= 0 && phaseIndex < CyclePhases.phases.length - 1) {
      return CyclePhases.phases[phaseIndex + 1].name;
    }
    return 'Menstrual'; // Loop back to menstrual phase
  }

  /// Get day range for a specific cycle length.
  /// For example, for a 28-day cycle: Days 1–5
  String getDayRange(int cycleLength) {
    int startDay = (startPercentage * cycleLength).ceil();
    int endDay = (endPercentage * cycleLength).floor();
    if (endDay < startDay) endDay = cycleLength;
    return 'Days $startDay–$endDay';
  }

  /// Check if a given cycle day falls within this phase.
  bool containsDay(int dayOfCycle, int cycleLength) {
    int startDay = (startPercentage * cycleLength).ceil();
    int endDay = (endPercentage * cycleLength).floor();
    if (endDay < startDay) endDay = cycleLength;
    return dayOfCycle >= startDay && dayOfCycle <= endDay;
  }
}

/// Static list of phases based on Dr. Mindy Pelz's cycle syncing framework.
/// Adapted for proportional calculations based on cycle length.
class CyclePhases {
  static const List<Phase> phases = [
    Phase(
      name: 'Menstrual',
      emoji: '🩸',
      description: 'Rest & Restore',
      dietName: 'Restorative Nutrition',
      workoutName: 'Low-Impact Training',
      fastingType: 'Power Fasting',
      startPercentage: 0.0,
      endPercentage: 0.179, // Days 1–5 for 28-day cycle
    ),
    Phase(
      name: 'Follicular',
      emoji: '🌱',
      description: 'High Energy Day',
      dietName: 'Energizing Nutrition',
      workoutName: 'Mid-Impact Training',
      fastingType: 'Power Fasting',
      startPercentage: 0.179,
      endPercentage: 0.429, // Days 6–12 for 28-day cycle
    ),
    Phase(
      name: 'Ovulation',
      emoji: '✨',
      description: 'Peak Energy',
      dietName: 'Light & Fresh',
      workoutName: 'Strength Training',
      fastingType: 'Manifestation Fasting',
      startPercentage: 0.429,
      endPercentage: 0.536, // Days 13–15 for 28-day cycle
    ),
    Phase(
      name: 'Early Luteal',
      emoji: '🌙',
      description: 'Building Energy',
      dietName: 'Balanced Nutrition',
      workoutName: 'Mid-Impact Training',
      fastingType: 'Power Fasting',
      startPercentage: 0.536,
      endPercentage: 0.714, // Days 16–20 for 28-day cycle
    ),
    Phase(
      name: 'Luteal',
      emoji: '🌙',
      description: 'Inward Focus',
      dietName: 'Calming Nutrition',
      workoutName: 'Mid- to Low-Impact Training',
      fastingType: 'Nurture Fasting',
      startPercentage: 0.714,
      endPercentage: 1.0, // Days 20–28 for 28-day cycle
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
  static Phase? findPhaseForDay(int dayOfCycle, int cycleLength) {
    try {
      return phases.firstWhere((phase) => phase.containsDay(dayOfCycle, cycleLength));
    } catch (e) {
      return null;
    }
  }

  /// Get all phase day ranges for a specific cycle length.
  static Map<String, String> getAllPhaseRanges(int cycleLength) {
    Map<String, String> ranges = {};
    for (Phase phase in phases) {
      ranges[phase.name] = phase.getDayRange(cycleLength);
    }
    return ranges;
  }
}
