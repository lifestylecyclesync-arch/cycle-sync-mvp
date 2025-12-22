import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';
import '../utils/favorites_manager.dart';

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
  List<String> _customMeals = [];
  Set<String> _favoriteMeals = {};

  @override
  void initState() {
    super.initState();
    _loadMealSuggestions();
    _loadSelectedMeal();
    _loadCustomMeals();
    _loadFavoriteMeals();
  }

  Future<void> _loadFavoriteMeals() async {
    final favorites = await FavoritesManager.getFavoriteMeals(widget.mealType);
    setState(() {
      _favoriteMeals = favorites;
    });
  }

  Future<void> _loadCustomMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final customStr = prefs.getString('custom_meals');
    setState(() {
      _customMeals = customStr?.split(',').where((item) => item.isNotEmpty).toList() ?? [];
    });
  }

  Future<void> _addCustomMeal(String meal) async {
    if (meal.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!_customMeals.contains(meal)) {
      _customMeals.add(meal);
      await prefs.setString('custom_meals', _customMeals.join(','));
      setState(() {});
    }
  }

  void _showAddCustomMealDialog() {
    String customMeal = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Meal'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g., Homemade pizza',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (value) => customMeal = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addCustomMeal(customMeal);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
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

  void _toggleMealSelection(String meal) {
    setState(() {
      // If clicking the same meal, deselect it; otherwise select the new one
      if (_selectedMeal == meal) {
        _selectedMeal = null;
      } else {
        _selectedMeal = meal;
      }
    });
  }

  Future<void> _saveMeal(String? meal) async {
    final prefs = await SharedPreferences.getInstance();
    String dateKey = 'nutrition_${widget.date.toIso8601String().split('T')[0]}_${widget.mealType}';
    
    if (meal == null) {
      // Clear the meal selection
      await prefs.remove(dateKey);
    } else {
      await prefs.setString(dateKey, meal);
    }
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildMealTile(String meal, bool isSelected, bool isFavorited, {bool isCustom = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () => _toggleMealSelection(meal),
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
                    if (isCustom || isFavorited)
                      Row(
                        children: [
                          if (isCustom)
                            Text(
                              'Custom',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meal,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        meal,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      FavoritesManager.toggleFavoriteMeal(meal, widget.mealType);
                      setState(() {
                        if (_favoriteMeals.contains(meal)) {
                          _favoriteMeals.remove(meal);
                        } else {
                          _favoriteMeals.add(meal);
                        }
                      });
                    },
                    child: Icon(
                      _favoriteMeals.contains(meal) ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> suggestions = (_mealSuggestions[widget.dietType]?[widget.mealType] ?? [])
        .where((meal) => !_favoriteMeals.contains(meal))
        .toList();
    
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
                          '🍽️ ${widget.mealType.capitalize()} Ideas',
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
                      widget.dietType,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.phase,
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
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: (_favoriteMeals.isNotEmpty ? 1 + _favoriteMeals.length : 0) + _customMeals.length + 1 + suggestions.length,
                  itemBuilder: (context, index) {
                    int currentIndex = index;

                    // Favorites header (if there are favorites)
                    if (_favoriteMeals.isNotEmpty) {
                      if (currentIndex == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                          child: Text(
                            '❤️ My Favorites',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                      
                      // Favorite meals items
                      if (currentIndex <= _favoriteMeals.length) {
                        String meal = _favoriteMeals.toList()[currentIndex - 1];
                        bool isSelected = _selectedMeal == meal;
                        return _buildMealTile(meal, isSelected, true);
                      }
                      
                      // Adjust index after favorites section
                      currentIndex -= (1 + _favoriteMeals.length);
                    }

                    // Custom meals section
                    if (currentIndex < _customMeals.length) {
                      String meal = _customMeals[currentIndex];
                      bool isSelected = _selectedMeal == meal;
                      return _buildMealTile(meal, isSelected, false, isCustom: true);
                    }

                    currentIndex -= _customMeals.length;

                    // Add Custom Meal button
                    if (currentIndex == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: _showAddCustomMealDialog,
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade300, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, color: Colors.orange.shade600),
                                const SizedBox(width: 12),
                                Text(
                                  'Add Custom Meal',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    currentIndex -= 1;

                    // Suggested meals
                    if (currentIndex < suggestions.length) {
                      String meal = suggestions[currentIndex];
                      bool isSelected = _selectedMeal == meal;
                      return _buildMealTile(meal, isSelected, false);
                    }

                    // Fallback (shouldn't reach here)
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveMeal(_selectedMeal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF333333),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFF333333), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: const Color(0xFFCCCCCC),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
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

extension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
