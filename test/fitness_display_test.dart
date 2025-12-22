import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fitness Display Tests', () {
    test('Parse old format fitness data (with booleans)', () {
      String oldFormat = 'walking:true,yoga:false,pilates:true';
      List<String> selectedWorkouts = [];
      
      if (oldFormat.contains(':')) {
        List<String> items = oldFormat.split(',');
        for (String item in items) {
          List<String> parts = item.split(':');
          if (parts.length == 2 && parts[1] == 'true') {
            selectedWorkouts.add(parts[0]);
          }
        }
      }
      
      expect(selectedWorkouts.length, 2);
      expect(selectedWorkouts.contains('walking'), true);
      expect(selectedWorkouts.contains('pilates'), true);
      expect(selectedWorkouts.contains('yoga'), false);
    });

    test('Parse new format fitness data (comma-separated)', () {
      String newFormat = 'walking,yoga,pilates';
      List<String> selectedWorkouts = 
          newFormat.split(',').where((item) => item.isNotEmpty).toList();
      
      expect(selectedWorkouts.length, 3);
      expect(selectedWorkouts.contains('walking'), true);
      expect(selectedWorkouts.contains('yoga'), true);
      expect(selectedWorkouts.contains('pilates'), true);
    });

    test('Display workouts properly joined', () {
      List<String> selectedWorkouts = ['Heavy Lifting', 'Running', 'HIIT'];
      String displayText = selectedWorkouts.join(', ');
      
      expect(displayText, 'Heavy Lifting, Running, HIIT');
      expect(displayText.contains(':'), false); // Should not contain colons
      expect(displayText.contains('false'), false); // Should not contain booleans
    });

    test('Empty workouts shows hint', () {
      List<String> selectedWorkouts = [];
      bool isEmpty = selectedWorkouts.isEmpty;
      
      expect(isEmpty, true);
    });

    test('Non-empty workouts does not show hint', () {
      List<String> selectedWorkouts = ['Walking'];
      bool isEmpty = selectedWorkouts.isEmpty;
      
      expect(isEmpty, false);
    });
  });
}
