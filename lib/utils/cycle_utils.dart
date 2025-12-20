import 'package:flutter/material.dart';

/// Determines the current cycle phase dynamically based on cycle length.
/// 
/// Parameters:
/// - `lastPeriodStart`: The start date of the last menstrual period.
/// - `cycleLength`: Average cycle length in days (typically 21-35).
/// - `today`: The current date to calculate against.
/// 
/// Returns a string representing the current phase:
/// - "Menstrual"
/// - "Follicular"
/// - "Ovulation"
/// - "Early Luteal"
/// - "Luteal"
/// 
/// Phase ranges scale proportionally to cycle length:
/// - Menstrual: Days 1–5 (fixed)
/// - Follicular: Days 6 until ~45% of cycle length
/// - Ovulation: ~45% to ~60% of cycle length (fertile window)
/// - Early Luteal: ~60% to ~75% of cycle length
/// - Luteal: ~75% to end of cycle
String getCyclePhase(
  DateTime lastPeriodStart,
  int cycleLength,
  DateTime today,
) {
  // Calculate which day of the cycle we're on (1-based)
  int dayOfCycle = (today.difference(lastPeriodStart).inDays % cycleLength) + 1;

  // Fixed menstrual phase (days 1-5)
  if (dayOfCycle <= 5) {
    return 'Menstrual';
  }

  // Calculate proportional boundaries
  double follicularEnd = cycleLength * 0.45;
  double ovulationEnd = cycleLength * 0.60;
  double earlyLutealEnd = cycleLength * 0.75;

  // Follicular phase: day 6 until ~45% of cycle
  if (dayOfCycle <= follicularEnd) {
    return 'Follicular';
  }

  // Ovulation phase: ~45% to ~60% of cycle
  if (dayOfCycle <= ovulationEnd) {
    return 'Ovulation';
  }

  // Early Luteal phase: ~60% to ~75% of cycle
  if (dayOfCycle <= earlyLutealEnd) {
    return 'Early Luteal';
  }

  // Luteal phase: ~75% to end of cycle
  return 'Luteal';
}

/// Returns the emoji representation of a cycle phase.
String getPhaseEmoji(String phase) {
  switch (phase) {
    case 'Menstrual':
      return '🩸';
    case 'Follicular':
      return '🌱';
    case 'Ovulation':
      return '✨';
    case 'Early Luteal':
      return '🌙';
    case 'Luteal':
      return '🌙';
    default:
      return '💫';
  }
}

/// Returns the faded color for a given cycle phase.
/// Colors are intentionally muted so they can be enhanced when data is logged.

Color getPhaseColor(String phase) {
  switch (phase) {
    case 'Menstrual':
      return const Color(0xFFEDD8D8); // Faded Pink
    case 'Follicular':
      return const Color(0xFFD8EFF8); // Faded Sky Blue
    case 'Ovulation':
      return const Color(0xFFEDD8D8); // Faded Pink
    case 'Early Luteal':
      return const Color(0xFFE8D8F8); // Faded Lavender
    case 'Luteal':
      return const Color(0xFFE8D8F8); // Faded Lavender
    default:
      return Colors.grey.shade100;
  }
}

/// Returns phase-specific energy/mood description.
String getPhaseDescription(String phase) {
  switch (phase) {
    case 'Menstrual':
      return 'Rest & Restore';
    case 'Follicular':
      return 'High Energy Day';
    case 'Ovulation':
      return 'Peak Energy';
    case 'Early Luteal':
      return 'Building Energy';
    case 'Luteal':
      return 'Inward Focus';
    default:
      return 'Cycle Tracking';
  }
}
