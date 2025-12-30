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

    test('Phase workout names are correct', () {
      Phase menstrual = CyclePhases.phases[0];
      Phase follicular = CyclePhases.phases[1];
      Phase ovulation = CyclePhases.phases[2];
      Phase earlyLuteal = CyclePhases.phases[3];
      Phase luteal = CyclePhases.phases[4];

      expect(menstrual.workoutName, 'Low-Impact Training');
      expect(follicular.workoutName, 'Mid-Impact Training');
      expect(ovulation.workoutName, 'Strength Training');
      expect(earlyLuteal.workoutName, 'Mid-Impact Training');
      expect(luteal.workoutName, 'Mid- to Low-Impact Training');
    });

    test('Phase names and data are correct', () {
      expect(CyclePhases.phases[0].name, 'Menstrual');
      expect(CyclePhases.phases[1].name, 'Follicular');
      expect(CyclePhases.phases[2].name, 'Ovulation');
      expect(CyclePhases.phases[3].name, 'Early Luteal');
      expect(CyclePhases.phases[4].name, 'Luteal');
    });
  });
}
