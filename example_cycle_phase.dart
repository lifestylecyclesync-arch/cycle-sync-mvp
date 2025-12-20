// Example: Using getCyclePhase with different cycle lengths

import 'package:cycle_sync_mvp/utils/cycle_utils.dart';

void main() {
  // Example 1: Standard 28-day cycle
  print('=== 28-Day Cycle ===');
  DateTime lastPeriod28 = DateTime(2024, 12, 1);
  int cycleLength28 = 28;
  
  // Day 1 (Dec 1) - Menstrual
  print('Dec 1: ${getCyclePhase(lastPeriod28, cycleLength28, DateTime(2024, 12, 1))}');
  
  // Day 12 (Dec 12) - Ovulation (~45% to 60%)
  print('Dec 12: ${getCyclePhase(lastPeriod28, cycleLength28, DateTime(2024, 12, 12))}');
  
  // Day 14 (Dec 14) - Ovulation
  print('Dec 14: ${getCyclePhase(lastPeriod28, cycleLength28, DateTime(2024, 12, 14))}');
  
  // Day 18 (Dec 18) - Early Luteal
  print('Dec 18: ${getCyclePhase(lastPeriod28, cycleLength28, DateTime(2024, 12, 18))}');
  
  // Day 22 (Dec 22) - Luteal
  print('Dec 22: ${getCyclePhase(lastPeriod28, cycleLength28, DateTime(2024, 12, 22))}');

  print('\n=== 25-Day Cycle (Shorter) ===');
  DateTime lastPeriod25 = DateTime(2024, 12, 1);
  int cycleLength25 = 25;
  
  // Phase ranges for 25-day cycle:
  // - Menstrual: 1-5
  // - Follicular: 6-11.25 (~45%)
  // - Ovulation: 11.25-15 (~60%)
  // - Early Luteal: 15-18.75 (~75%)
  // - Luteal: 18.75-25
  
  print('Day 10: ${getCyclePhase(lastPeriod25, cycleLength25, DateTime(2024, 12, 10))}'); // Follicular
  print('Day 13: ${getCyclePhase(lastPeriod25, cycleLength25, DateTime(2024, 12, 13))}'); // Ovulation
  print('Day 17: ${getCyclePhase(lastPeriod25, cycleLength25, DateTime(2024, 12, 17))}'); // Early Luteal
  print('Day 20: ${getCyclePhase(lastPeriod25, cycleLength25, DateTime(2024, 12, 20))}'); // Luteal

  print('\n=== 32-Day Cycle (Longer) ===');
  DateTime lastPeriod32 = DateTime(2024, 12, 1);
  int cycleLength32 = 32;
  
  // Phase ranges for 32-day cycle:
  // - Menstrual: 1-5
  // - Follicular: 6-14.4 (~45%)
  // - Ovulation: 14.4-19.2 (~60%)
  // - Early Luteal: 19.2-24 (~75%)
  // - Luteal: 24-32
  
  print('Day 10: ${getCyclePhase(lastPeriod32, cycleLength32, DateTime(2024, 12, 10))}'); // Follicular
  print('Day 16: ${getCyclePhase(lastPeriod32, cycleLength32, DateTime(2024, 12, 16))}'); // Ovulation
  print('Day 20: ${getCyclePhase(lastPeriod32, cycleLength32, DateTime(2024, 12, 20))}'); // Early Luteal
  print('Day 26: ${getCyclePhase(lastPeriod32, cycleLength32, DateTime(2024, 12, 26))}'); // Luteal

  print('\n=== Using Emojis and Colors ===');
  String phase = getCyclePhase(lastPeriod28, cycleLength28, DateTime.now());
  String emoji = getPhaseEmoji(phase);
  String description = getPhaseDescription(phase);
  
  print('Current Phase: $phase $emoji');
  print('Description: $description');
}

/*
OUTPUT (when run on Dec 20, 2024):
=== 28-Day Cycle ===
Dec 1: Menstrual
Dec 12: Ovulation
Dec 14: Ovulation
Dec 18: Early Luteal
Dec 22: Luteal

=== 25-Day Cycle (Shorter) ===
Day 10: Follicular
Day 13: Ovulation
Day 17: Early Luteal
Day 20: Luteal

=== 32-Day Cycle (Longer) ===
Day 10: Follicular
Day 16: Ovulation
Day 20: Early Luteal
Day 26: Luteal

=== Using Emojis and Colors ===
Current Phase: Early Luteal 🌙
Description: Building Energy
*/
