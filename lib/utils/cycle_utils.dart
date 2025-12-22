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
/// Phase ranges scale proportionally to cycle length (Dr. Mindy Pelz framework):
/// - Menstrual: 0% to 17.9% (Days 1–5 for 28-day cycle)
/// - Follicular: 17.9% to 42.9% (Days 6–12 for 28-day cycle)
/// - Ovulation: 42.9% to 53.6% (Days 13–15 for 28-day cycle)
/// - Early Luteal: 53.6% to 71.4% (Days 16–20 for 28-day cycle)
/// - Luteal: 71.4% to 100% (Days 20–28 for 28-day cycle)
String getCyclePhase(
  DateTime lastPeriodStart,
  int cycleLength,
  DateTime today,
) {
  // Calculate which day of the cycle we're on (1-based)
  int dayOfCycle = (today.difference(lastPeriodStart).inDays % cycleLength) + 1;
  double cycleProgress = dayOfCycle / cycleLength;

  // Calculate proportional boundaries
  const double menstrualEnd = 0.179;
  const double follicularEnd = 0.429;
  const double ovulationEnd = 0.536;
  const double earlyLutealEnd = 0.714;

  // Menstrual phase: 0% to 17.9%
  if (cycleProgress <= menstrualEnd) {
    return 'Menstrual';
  }

  // Follicular phase: 17.9% to 42.9%
  if (cycleProgress <= follicularEnd) {
    return 'Follicular';
  }

  // Ovulation phase: 42.9% to 53.6%
  if (cycleProgress <= ovulationEnd) {
    return 'Ovulation';
  }

  // Early Luteal phase: 53.6% to 71.4%
  if (cycleProgress <= earlyLutealEnd) {
    return 'Early Luteal';
  }

  // Luteal phase: 71.4% to 100%
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
