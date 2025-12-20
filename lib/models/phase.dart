/// Data model for menstrual cycle phases based on Dr. Mindy Pelz's cycle syncing framework.
class Phase {
  final String name;
  final String emoji;
  final String description;
  final String dietName;
  final String workoutName;
  final double startPercentage; // Start of phase as % of cycle (0.0 - 1.0)
  final double endPercentage;   // End of phase as % of cycle (0.0 - 1.0)

  const Phase({
    required this.name,
    required this.emoji,
    required this.description,
    required this.dietName,
    required this.workoutName,
    required this.startPercentage,
    required this.endPercentage,
  });

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
      workoutName: 'Gentle / Low-Impact Training',
      startPercentage: 0.0,
      endPercentage: 0.18, // Days 1–5 for 28-day cycle
    ),
    Phase(
      name: 'Follicular',
      emoji: '🌱',
      description: 'High Energy Day',
      dietName: 'Energizing Nutrition',
      workoutName: 'Build / Mid-Impact Training',
      startPercentage: 0.18,
      endPercentage: 0.45, // Days 6–11 for 28-day cycle
    ),
    Phase(
      name: 'Ovulation',
      emoji: '✨',
      description: 'Peak Energy',
      dietName: 'Light & Fresh Nutrition',
      workoutName: 'Peak / Strength Training',
      startPercentage: 0.45,
      endPercentage: 0.60, // Days 12–16 for 28-day cycle
    ),
    Phase(
      name: 'Early Luteal',
      emoji: '🌙',
      description: 'Building Energy',
      dietName: 'Balanced Nutrition',
      workoutName: 'Sustain / Mid-Impact Training',
      startPercentage: 0.60,
      endPercentage: 0.75, // Days 17–21 for 28-day cycle
    ),
    Phase(
      name: 'Luteal',
      emoji: '🌙',
      description: 'Inward Focus',
      dietName: 'Calming Nutrition',
      workoutName: 'Restore / Mid- to Low-Impact Training',
      startPercentage: 0.75,
      endPercentage: 1.0, // Days 22–28 for 28-day cycle
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
