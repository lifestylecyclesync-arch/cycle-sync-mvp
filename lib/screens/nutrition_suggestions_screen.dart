import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';

class NutritionSuggestionsScreen extends StatefulWidget {
  final String mealType; // breakfast, lunch, dinner, snack
  final String dietType; // From Phase model
  final String phase;
  final DateTime date;

  const NutritionSuggestionsScreen({
    super.key,
    required this.mealType,
    required this.dietType,
    required this.phase,
    required this.date,
  });

  @override
  State<NutritionSuggestionsScreen> createState() => _NutritionSuggestionsScreenState();
}

class _NutritionSuggestionsScreenState extends State<NutritionSuggestionsScreen> {
  late Map<String, Map<String, List<String>>> _mealSuggestions;
  String? _selectedMeal;

  @override
  void initState() {
    super.initState();
    _loadMealSuggestions();
    _loadSelectedMeal();
  }

  void _loadMealSuggestions() {
    // Meal suggestions based on diet type
    _mealSuggestions = {
      'Restorative Nutrition': {
        'breakfast': [
          'Warm oatmeal with berries & honey',
          'Sweet potato toast with almond butter',
          'Bone broth with soft vegetables',
          'Smoothie bowl with chia seeds',
          'Eggs with whole grain toast',
        ],
        'lunch': [
          'Salmon with roasted vegetables',
          'Chicken soup with healing broth',
          'Quinoa bowl with roasted veggies',
          'Turkey meatballs with sweet potato',
          'Lentil soup with leafy greens',
        ],
        'dinner': [
          'Beef stew with root vegetables',
          'Baked white fish with asparagus',
          'Slow-cooked pork with carrots',
          'Vegetable curry with rice',
          'Roasted chicken with herbs',
        ],
        'snack': [
          'Herbal tea with dates',
          'Homemade energy balls',
          'Apple with almond butter',
          'Warm nut milk',
          'Dark chocolate & almonds',
        ],
      },
      'Energizing Nutrition': {
        'breakfast': [
          'Greek yogurt with granola & fruit',
          'Veggie omelet with whole wheat toast',
          'Green smoothie with spinach',
          'Protein pancakes with berries',
          'Avocado toast with poached eggs',
        ],
        'lunch': [
          'Grilled chicken salad',
          'Tuna poke bowl',
          'Falafel wrap with hummus',
          'Quinoa & veggie bowl',
          'Lean beef tacos with lettuce',
        ],
        'dinner': [
          'Grilled salmon with broccoli',
          'Chicken stir-fry with veggies',
          'Shrimp pasta with tomato sauce',
          'Turkey meatballs with zucchini',
          'Grilled cod with green beans',
        ],
        'snack': [
          'Greek yogurt with nuts',
          'Fresh fruit salad',
          'Veggie sticks with hummus',
          'Protein bar',
          'Mixed berries',
        ],
      },
      'Light & Fresh': {
        'breakfast': [
          'Light salad with egg',
          'Fruit smoothie bowl',
          'Cottage cheese with berries',
          'Whole grain toast with tomato',
          'Granola with yogurt',
        ],
        'lunch': [
          'Caprese salad',
          'Sushi rolls',
          'Light seafood salad',
          'Mixed greens with grilled chicken',
          'Fresh pasta with vegetables',
        ],
        'dinner': [
          'Grilled white fish with asparagus',
          'Light vegetable stir-fry',
          'Shrimp with watermelon radish',
          'Cucumber gazpacho',
          'Grilled vegetables with herbs',
        ],
        'snack': [
          'Watermelon slices',
          'Cucumber with mint',
          'Light fruit sorbet',
          'Sparkling water with lemon',
          'Light yogurt',
        ],
      },
      'Balanced Nutrition': {
        'breakfast': [
          'Balanced breakfast bowl',
          'Oatmeal with nuts & fruit',
          'Eggs with toast & veggies',
          'Yogurt parfait',
          'Smoothie with protein powder',
        ],
        'lunch': [
          'Balanced Buddha bowl',
          'Lean protein with sides',
          'Wrap with veggies & protein',
          'Balanced salad with nuts',
          'Rice bowl with protein & veggies',
        ],
        'dinner': [
          'Baked chicken with sweet potato',
          'Salmon with brown rice',
          'Lean meat with balanced sides',
          'Fish with quinoa & veggies',
          'Turkey with roasted vegetables',
        ],
        'snack': [
          'Nuts & dried fruit',
          'Cheese & crackers',
          'Protein shake',
          'Apple with nut butter',
          'Mixed nuts',
        ],
      },
      'Calming Nutrition': {
        'breakfast': [
          'Warm porridge with spices',
          'Herbal tea with toast',
          'Warm milk with honey',
          'Slow-cooked grains',
          'Baked fruit with spices',
        ],
        'lunch': [
          'Warm soup with greens',
          'Roasted vegetables with grains',
          'Slow-cooked stew',
          'Braised vegetables',
          'Warm grain salad',
        ],
        'dinner': [
          'Slow-cooked root vegetables',
          'Warming spiced curry',
          'Roasted root vegetable medley',
          'Warming soup',
          'Braised leafy greens',
        ],
        'snack': [
          'Warm herbal tea',
          'Baked apple',
          'Warm nut milk with spices',
          'Herbal infusion',
          'Dates with nuts',
        ],
      },
    };
  }

  Future<void> _loadSelectedMeal() async {
    final prefs = await SharedPreferences.getInstance();
    String dateKey = 'nutrition_${widget.date.toIso8601String().split('T')[0]}_${widget.mealType}';
    final selected = prefs.getString(dateKey);
    setState(() {
      _selectedMeal = selected;
    });
  }

  Future<void> _saveMeal(String meal) async {
    final prefs = await SharedPreferences.getInstance();
    String dateKey = 'nutrition_${widget.date.toIso8601String().split('T')[0]}_${widget.mealType}';
    await prefs.setString(dateKey, meal);
    setState(() {
      _selectedMeal = meal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$meal saved for ${widget.mealType}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> suggestions = _mealSuggestions[widget.dietType]?[widget.mealType] ?? [];
    
    return GradientWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '${widget.mealType.capitalize()} Ideas',
            style: const TextStyle(
              color: Color(0xFF333333),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.phase,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.dietType,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    String meal = suggestions[index];
                    bool isSelected = _selectedMeal == meal;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () => _saveMeal(meal),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.grey.shade200 : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF333333) : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      meal,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF333333),
                                        decoration: isSelected ? TextDecoration.none : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF333333),
                                  size: 24,
                                )
                              else
                                const Icon(
                                  Icons.radio_button_unchecked,
                                  color: Color(0xFF999999),
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
