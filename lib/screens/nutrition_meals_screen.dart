import 'package:flutter/material.dart';
import 'nutrition_suggestions_screen.dart';
import '../widgets/gradient_wrapper.dart';

class NutritionMealsScreen extends StatelessWidget {
  final String dietType;
  final String phase;
  final DateTime date;

  const NutritionMealsScreen({
    super.key,
    required this.dietType,
    required this.phase,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final meals = [
      {'name': 'Breakfast', 'emoji': '🌅'},
      {'name': 'Lunch', 'emoji': '🍽️'},
      {'name': 'Dinner', 'emoji': '🌙'},
      {'name': 'Snack', 'emoji': '🍿'},
    ];

    return GradientWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Select a Meal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            children: meals.map((meal) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NutritionSuggestionsScreen(
                        mealType: meal['name']!.toLowerCase(),
                        dietType: dietType,
                        phase: phase,
                        date: date,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          meal['emoji']!,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          meal['name']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
