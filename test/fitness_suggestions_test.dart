import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_sync_mvp/models/phase.dart';

void main() {
  group('Fitness Suggestions Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Toggle workout adds to selected set', () {
      Set<String> selectedWorkouts = {};
      String workout = 'Heavy Lifting';

      // Toggle on
      if (selectedWorkouts.contains(workout)) {
        selectedWorkouts.remove(workout);
      } else {
        selectedWorkouts.add(workout);
      }

      expect(selectedWorkouts.contains(workout), true);
      expect(selectedWorkouts.length, 1);
    });

    test('Toggle workout removes from selected set', () {
      Set<String> selectedWorkouts = {'Heavy Lifting', 'Running'};
      String workout = 'Heavy Lifting';

      // Toggle off
      if (selectedWorkouts.contains(workout)) {
        selectedWorkouts.remove(workout);
      } else {
        selectedWorkouts.add(workout);
      }

      expect(selectedWorkouts.contains(workout), false);
      expect(selectedWorkouts.length, 1);
    });

    test('Save multiple workouts to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      Set<String> selectedWorkouts = {'Heavy Lifting', 'Running', 'HIIT'};
      String dateKey = 'fitness_2025-12-22';

      // Save
      await prefs.setString(dateKey, selectedWorkouts.join(','));
      
      // Verify
      final saved = prefs.getString(dateKey);
      expect(saved, isNotNull);
      expect(saved!.split(',').length, 3);
    });

    test('Load workouts from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      String dateKey = 'fitness_2025-12-22';
      
      // Save
      await prefs.setString(dateKey, 'Heavy Lifting,Running,HIIT');
      
      // Load
      final selectedJson = prefs.getString(dateKey);
      Set<String> selectedWorkouts = {};
      if (selectedJson != null && selectedJson.isNotEmpty) {
        selectedWorkouts = Set<String>.from(
          selectedJson.split(',').where((item) => item.isNotEmpty)
        );
      }

      expect(selectedWorkouts.length, 3);
      expect(selectedWorkouts.contains('Heavy Lifting'), true);
      expect(selectedWorkouts.contains('Running'), true);
    });

    test('Clear workouts from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      String dateKey = 'fitness_2025-12-22';
      
      // Save
      await prefs.setString(dateKey, 'Heavy Lifting,Running');
      
      // Clear
      await prefs.remove(dateKey);
      
      // Verify
      final saved = prefs.getString(dateKey);
      expect(saved, isNull);
    });

    test('Empty workout selection saves as empty', () async {
      final prefs = await SharedPreferences.getInstance();
      Set<String> selectedWorkouts = {};
      String dateKey = 'fitness_2025-12-22';

      // Save empty set
      if (selectedWorkouts.isEmpty) {
        await prefs.remove(dateKey);
      } else {
        await prefs.setString(dateKey, selectedWorkouts.join(','));
      }

      // Verify
      final saved = prefs.getString(dateKey);
      expect(saved, isNull);
    });

    test('Phase workout types are correct', () {
      Phase menstrual = CyclePhases.phases[0];
      Phase follicular = CyclePhases.phases[2];
      Phase ovulation = CyclePhases.phases[4];
      Phase earlyLuteal = CyclePhases.phases[5];
      Phase luteal = CyclePhases.phases[6];

      expect(menstrual.workoutType.isNotEmpty, true);
      expect(follicular.workoutType.isNotEmpty, true);
      expect(ovulation.workoutType.isNotEmpty, true);
      expect(earlyLuteal.workoutType.isNotEmpty, true);
      expect(luteal.workoutType.isNotEmpty, true);
    });

    test('Phase names match current phase list', () {
      expect(CyclePhases.phases[0].name, 'Menstrual (Days 1 to ML-1)');
      expect(CyclePhases.phases[1].name, 'Menstrual (Day ML)');
      expect(CyclePhases.phases[2].name, 'Follicular (Early)');
      expect(CyclePhases.phases[3].name, 'Follicular (Late)');
      expect(CyclePhases.phases[4].name, 'Ovulation');
      expect(CyclePhases.phases[5].name, 'Early Luteal');
      expect(CyclePhases.phases[6].name, 'Luteal (Late)');
    });
  });
}
