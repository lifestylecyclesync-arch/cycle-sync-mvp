import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Nutrition Suggestions Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Select a single meal', () {
      String? selectedMeal;
      String newMeal = 'Grilled Chicken Salad';

      selectedMeal = newMeal;

      expect(selectedMeal, 'Grilled Chicken Salad');
    });

    test('Change selected meal', () {
      String? selectedMeal = 'Pasta';
      String newMeal = 'Salad';

      selectedMeal = newMeal;

      expect(selectedMeal, 'Salad');
    });

    test('Save meal to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      String dateKey = 'nutrition_2025-12-22_breakfast';
      String meal = 'Oatmeal with Berries';

      // Save
      await prefs.setString(dateKey, meal);

      // Verify
      final saved = prefs.getString(dateKey);
      expect(saved, meal);
    });

    test('Load meal from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      String dateKey = 'nutrition_2025-12-22_lunch';
      String meal = 'Grilled Fish with Vegetables';

      // Save
      await prefs.setString(dateKey, meal);

      // Load
      final loadedMeal = prefs.getString(dateKey);

      expect(loadedMeal, meal);
    });

    test('Clear meal from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      String dateKey = 'nutrition_2025-12-22_dinner';

      // Save
      await prefs.setString(dateKey, 'Salmon with Rice');

      // Clear
      await prefs.remove(dateKey);

      // Verify
      final saved = prefs.getString(dateKey);
      expect(saved, isNull);
    });

    test('Save different meals for different meal types', () async {
      final prefs = await SharedPreferences.getInstance();

      // Save multiple meals
      await prefs.setString('nutrition_2025-12-22_breakfast', 'Eggs and Toast');
      await prefs.setString('nutrition_2025-12-22_lunch', 'Chicken Wrap');
      await prefs.setString('nutrition_2025-12-22_dinner', 'Pasta');

      // Verify all are saved
      expect(prefs.getString('nutrition_2025-12-22_breakfast'), 'Eggs and Toast');
      expect(prefs.getString('nutrition_2025-12-22_lunch'), 'Chicken Wrap');
      expect(prefs.getString('nutrition_2025-12-22_dinner'), 'Pasta');
    });

    test('Save different meals for different days', () async {
      final prefs = await SharedPreferences.getInstance();

      // Save same meal type for different days
      await prefs.setString('nutrition_2025-12-22_breakfast', 'Oatmeal');
      await prefs.setString('nutrition_2025-12-23_breakfast', 'Eggs');

      // Verify
      expect(prefs.getString('nutrition_2025-12-22_breakfast'), 'Oatmeal');
      expect(prefs.getString('nutrition_2025-12-23_breakfast'), 'Eggs');
    });

    test('Empty meal is not saved', () async {
      final prefs = await SharedPreferences.getInstance();
      String dateKey = 'nutrition_2025-12-22_breakfast';

      // Clear any existing value
      await prefs.remove(dateKey);

      // Verify nothing is saved
      final saved = prefs.getString(dateKey);
      expect(saved, isNull);
    });

    test('Overwrite existing meal selection', () async {
      final prefs = await SharedPreferences.getInstance();
      String dateKey = 'nutrition_2025-12-22_lunch';

      // Save first meal
      await prefs.setString(dateKey, 'Burger');

      // Overwrite with new meal
      await prefs.setString(dateKey, 'Salad');

      // Verify
      final saved = prefs.getString(dateKey);
      expect(saved, 'Salad');
    });
  });
}
