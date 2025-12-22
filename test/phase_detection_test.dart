import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_sync_mvp/models/phase.dart';

void main() {
  group('Phase Detection Tests', () {
    test('Phase boundaries are contiguous with no gaps', () {
      Phase phase1 = CyclePhases.phases[0];
      Phase phase2 = CyclePhases.phases[1];
      Phase phase3 = CyclePhases.phases[2];
      Phase phase4 = CyclePhases.phases[3];
      Phase phase5 = CyclePhases.phases[4];

      // Verify each phase starts where previous ends
      expect(phase2.startPercentage, phase1.endPercentage);
      expect(phase3.startPercentage, phase2.endPercentage);
      expect(phase4.startPercentage, phase3.endPercentage);
      expect(phase5.startPercentage, phase4.endPercentage);

      // Verify last phase ends at 100%
      expect(phase5.endPercentage, 1.0);

      // Verify first phase starts at 0%
      expect(phase1.startPercentage, 0.0);
    });

    test('All cycle days are covered by phases', () {
      double coverage = 0.0;
      for (Phase phase in CyclePhases.phases) {
        coverage += (phase.endPercentage - phase.startPercentage);
      }
      expect(coverage, closeTo(1.0, 0.01));
    });

    test('Detect correct phase for day 1 (Menstrual)', () {
      int cycleLength = 28;
      int dayNumber = 1;
      double dayPercentage = (dayNumber - 1) / cycleLength;

      Phase? detectedPhase;
      for (Phase phase in CyclePhases.phases) {
        if (dayPercentage >= phase.startPercentage &&
            dayPercentage < phase.endPercentage) {
          detectedPhase = phase;
          break;
        }
      }

      expect(detectedPhase, isNotNull);
      expect(detectedPhase!.name, 'Menstrual');
      expect(detectedPhase.workoutName, 'Low-Impact Training');
    });

    test('Detect correct phase for day 7 (Follicular)', () {
      int cycleLength = 28;
      int dayNumber = 7;
      double dayPercentage = (dayNumber - 1) / cycleLength;

      Phase? detectedPhase;
      for (Phase phase in CyclePhases.phases) {
        if (dayPercentage >= phase.startPercentage &&
            dayPercentage < phase.endPercentage) {
          detectedPhase = phase;
          break;
        }
      }

      expect(detectedPhase, isNotNull);
      expect(detectedPhase!.name, 'Follicular');
      expect(detectedPhase.workoutName, 'Mid-Impact Training');
    });

    test('Detect correct phase for day 14 (Ovulation)', () {
      int cycleLength = 28;
      int dayNumber = 14;
      double dayPercentage = (dayNumber - 1) / cycleLength;

      Phase? detectedPhase;
      for (Phase phase in CyclePhases.phases) {
        if (dayPercentage >= phase.startPercentage &&
            dayPercentage < phase.endPercentage) {
          detectedPhase = phase;
          break;
        }
      }

      expect(detectedPhase, isNotNull);
      expect(detectedPhase!.name, 'Ovulation');
      expect(detectedPhase.workoutName, 'Strength Training');
    });

    test('Detect correct phase for day 18 (Early Luteal)', () {
      int cycleLength = 28;
      int dayNumber = 18;
      double dayPercentage = (dayNumber - 1) / cycleLength;

      Phase? detectedPhase;
      for (Phase phase in CyclePhases.phases) {
        if (dayPercentage >= phase.startPercentage &&
            dayPercentage < phase.endPercentage) {
          detectedPhase = phase;
          break;
        }
      }

      expect(detectedPhase, isNotNull);
      expect(detectedPhase!.name, 'Early Luteal');
      expect(detectedPhase.workoutName, 'Mid-Impact Training');
    });

    test('Detect correct phase for day 23 (Luteal)', () {
      int cycleLength = 28;
      int dayNumber = 23;
      double dayPercentage = (dayNumber - 1) / cycleLength;

      Phase? detectedPhase;
      for (Phase phase in CyclePhases.phases) {
        if (dayPercentage >= phase.startPercentage &&
            dayPercentage < phase.endPercentage) {
          detectedPhase = phase;
          break;
        }
      }

      expect(detectedPhase, isNotNull);
      expect(detectedPhase!.name, 'Luteal');
      expect(detectedPhase.workoutName, 'Mid- to Low-Impact Training');
    });

    test('Phase detection works for 25-day cycle', () {
      int cycleLength = 25;
      int dayNumber = 1;
      double dayPercentage = (dayNumber - 1) / cycleLength;

      Phase? detectedPhase;
      for (Phase phase in CyclePhases.phases) {
        if (dayPercentage >= phase.startPercentage &&
            dayPercentage < phase.endPercentage) {
          detectedPhase = phase;
          break;
        }
      }

      expect(detectedPhase, isNotNull);
      expect(detectedPhase!.name, 'Menstrual');
    });

    test('Phase detection works for 35-day cycle', () {
      int cycleLength = 35;
      int dayNumber = 35;
      double dayPercentage = (dayNumber - 1) / cycleLength;

      Phase? detectedPhase;
      for (Phase phase in CyclePhases.phases) {
        if (dayPercentage >= phase.startPercentage &&
            dayPercentage < phase.endPercentage) {
          detectedPhase = phase;
          break;
        }
      }

      expect(detectedPhase, isNotNull);
    });

    test('Day range calculation for 28-day cycle', () {
      Phase menstrual = CyclePhases.phases[0];
      expect(menstrual.getDayRange(28), 'Days 1–5');
    });

    test('Day range calculation for 32-day cycle', () {
      Phase menstrual = CyclePhases.phases[0];
      expect(menstrual.getDayRange(32), 'Days 1–6');
    });

    test('All phases have valid percentage ranges', () {
      for (Phase phase in CyclePhases.phases) {
        expect(phase.startPercentage >= 0.0, true);
        expect(phase.endPercentage <= 1.0, true);
        expect(phase.endPercentage > phase.startPercentage, true);
      }
    });

    test('Phase names are not empty', () {
      for (Phase phase in CyclePhases.phases) {
        expect(phase.name.isNotEmpty, true);
        expect(phase.workoutName.isNotEmpty, true);
      }
    });
  });
}
