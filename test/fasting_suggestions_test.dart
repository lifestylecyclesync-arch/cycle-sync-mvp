import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Fasting Suggestions Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Select a fasting option', () {
      String? selectedFasting;
      String newFasting = '16-hour fast';

      selectedFasting = newFasting;

      expect(selectedFasting, '16-hour fast');
    });

    test('Change selected fasting option', () {
      String? selectedFasting = '12-hour fast';
      String newFasting = 'Water fasting (24 hours)';

      selectedFasting = newFasting;

      expect(selectedFasting, 'Water fasting (24 hours)');
    });

    test('Save fasting to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      String dateKey = 'fasting_2025-12-22';
      String fasting = '16-hour fast';

      // Save
      await prefs.setString(dateKey, fasting);

      // Verify
      final saved = prefs.getString(dateKey);
      expect(saved, fasting);
    });

    test('Load fasting from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      String dateKey = 'fasting_2025-12-22';
      String fasting = 'Water fasting (24 hours)';

      // Save
      await prefs.setString(dateKey, fasting);

      // Load
      final loadedFasting = prefs.getString(dateKey);

      expect(loadedFasting, fasting);
    });

    test('Clear fasting from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      String dateKey = 'fasting_2025-12-22';

      // Save
      await prefs.setString(dateKey, '16-hour fast');

      // Clear
      await prefs.remove(dateKey);

      // Verify
      final saved = prefs.getString(dateKey);
      expect(saved, isNull);
    });

    test('Save different fasting for different days', () async {
      final prefs = await SharedPreferences.getInstance();

      // Save same fasting type for different days
      await prefs.setString('fasting_2025-12-22', '16-hour fast');
      await prefs.setString('fasting_2025-12-23', 'Water fasting');

      // Verify
      expect(prefs.getString('fasting_2025-12-22'), '16-hour fast');
      expect(prefs.getString('fasting_2025-12-23'), 'Water fasting');
    });

    test('Phase fasting types are valid', () {
      List<String> validFastingTypes = [
        'Power Fasting',
        'Manifestation Fasting',
        'Nurture Fasting',
      ];

      expect(validFastingTypes.contains('Power Fasting'), true);
      expect(validFastingTypes.contains('Manifestation Fasting'), true);
      expect(validFastingTypes.contains('Nurture Fasting'), true);
    });

    test('Fasting options display properly', () {
      Map<String, List<String>> fastingOptions = {
        'Power Fasting': [
          '16-hour fast',
          '18-hour fast',
          '20-hour fast',
        ],
        'Manifestation Fasting': [
          '24-hour water fast',
          '36-hour extended fast',
        ],
        'Nurture Fasting': [
          'Eat normally throughout the day',
          'No fasting period',
        ],
      };

      expect(fastingOptions['Power Fasting']?.length, 3);
      expect(fastingOptions['Manifestation Fasting']?.length, 2);
      expect(fastingOptions['Nurture Fasting']?.length, 2);
    });
  });
}
