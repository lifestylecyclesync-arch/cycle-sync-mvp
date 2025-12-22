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
        body: SafeArea(
          child: Column(
            children: [
              // Standardized Header with Nutrition Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.withValues(alpha: 0.3),
                      Colors.orange.withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🍽️ Nutrition',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF333333)),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dietType,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phase,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
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
            ],
          ),
        ),
      ),
    );
  }
}
