import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_sync_mvp/models/phase.dart';
import 'package:cycle_sync_mvp/utils/cycle_utils.dart';

void main() {
  group('Phase Detection Tests', () {
    test('All 7 phases exist with correct names', () {
      expect(CyclePhases.phases.length, 7);
      expect(CyclePhases.phases[0].name, 'Menstrual (Days 1 to ML-1)');
      expect(CyclePhases.phases[1].name, 'Menstrual (Day ML)');
      expect(CyclePhases.phases[2].name, 'Follicular (Early)');
      expect(CyclePhases.phases[3].name, 'Follicular (Late)');
      expect(CyclePhases.phases[4].name, 'Ovulation');
      expect(CyclePhases.phases[5].name, 'Early Luteal');
      expect(CyclePhases.phases[6].name, 'Luteal (Late)');
    });

    test('All phases have required properties', () {
      for (Phase phase in CyclePhases.phases) {
        expect(phase.name.isNotEmpty, true);
        expect(phase.emoji.isNotEmpty, true);
        expect(phase.description.isNotEmpty, true);
        expect(phase.hormonalState.isNotEmpty, true);
        expect(phase.lifestylePhase.isNotEmpty, true);
        expect(phase.dietType.isNotEmpty, true);
        expect(phase.fastingDuration.isNotEmpty, true);
      }
    });

    test('Detect correct phase for day 1 (Menstrual Days 1 to ML-1)', () {
      DateTime lastPeriodStart = DateTime(2025, 12, 15);
      int cycleLength = 28;
      int menstrualLength = 5;
      DateTime dayOne = DateTime(2025, 12, 15);

      String phase = getCyclePhase(lastPeriodStart, cycleLength, dayOne,
          menstrualLength: menstrualLength);

      expect(phase, 'Menstrual (Days 1 to ML-1)');
      
      Phase? phaseData = CyclePhases.findPhaseByName(phase);
      expect(phaseData?.workoutType, 'gentle strength / restorative');
    });

    test('Detect correct phase for day 7 (Follicular Early)', () {
      DateTime lastPeriodStart = DateTime(2025, 12, 15);
      int cycleLength = 28;
      int menstrualLength = 5;
      DateTime dayNine = DateTime(2025, 12, 21); // Day 7 of cycle

      String phase = getCyclePhase(lastPeriodStart, cycleLength, dayNine,
          menstrualLength: menstrualLength);

      expect(phase, 'Follicular (Early)');
      
      Phase? phaseData = CyclePhases.findPhaseByName(phase);
      expect(phaseData?.workoutType, 'High‑intensity, strength‑focused');
    });

    test('Detect correct phase for day 14 (Ovulation)', () {
      DateTime lastPeriodStart = DateTime(2025, 12, 15);
      int cycleLength = 28;
      int menstrualLength = 5;
      DateTime day14 = DateTime(2025, 12, 28); // Day 14 of cycle

      String phase = getCyclePhase(lastPeriodStart, cycleLength, day14,
          menstrualLength: menstrualLength);

      expect(phase, 'Ovulation');
      
      Phase? phaseData = CyclePhases.findPhaseByName(phase);
      expect(phaseData?.workoutType, isNotEmpty
    });

    test('3-day ovulation window (OD-1 to OD+1)', () {
      DateTime lastPeriodStart = DateTime(2025, 12, 15);
      int cycleLength = 28;
      int menstrualLength = 5;
      
      // OD = 14, so ovulation should be Days 13-15
      for (int day = 13; day <= 15; day++) {
        DateTime dateToCheck = lastPeriodStart.add(Duration(days: day - 1));
        String phase = getCyclePhase(lastPeriodStart, cycleLength, dateToCheck,
            menstrualLength: menstrualLength);
        expect(phase, 'Ovulation', 
            reason: 'Day $day should be Ovulation phase');
      }
    });

    test('Follicular phase ends before ovulation', () {
      DateTime lastPeriodStart = DateTime(2025, 12, 15);
      int cycleLength = 28;
      int menstrualLength = 5;
      
      // Day 12 should be Follicular (Late), Day 13 should be Ovulation
      DateTime day12 = lastPeriodStart.add(Duration(days: 11));
      DateTime day13 = lastPeriodStart.add(Duration(days: 12));
      
      String phaseDay12 = getCyclePhase(lastPeriodStart, cycleLength, day12,
          menstrualLength: menstrualLength);
      String phaseDay13 = getCyclePhase(lastPeriodStart, cycleLength, day13,
          menstrualLength: menstrualLength);
      
      expect(phaseDay12, 'Follicular (Late)');
      expect(phaseDay13, 'Ovulation');
    });
  });
}
