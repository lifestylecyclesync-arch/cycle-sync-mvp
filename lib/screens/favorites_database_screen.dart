import 'package:flutter/material.dart';
import '../widgets/gradient_wrapper.dart';
import '../utils/favorites_manager.dart';

class FavoritesDatabaseScreen extends StatefulWidget {
  const FavoritesDatabaseScreen({super.key});

  @override
  State<FavoritesDatabaseScreen> createState() => _FavoritesDatabaseScreenState();
}

class _FavoritesDatabaseScreenState extends State<FavoritesDatabaseScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  Set<String> _favoriteMealsBreakfast = {};
  Set<String> _favoriteMealsLunch = {};
  Set<String> _favoriteMealsDinner = {};
  Set<String> _favoriteMealsSnack = {};
  Set<String> _favoriteWorkouts = {};
  Set<String> _favoriteFasting = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAllFavorites();
  }

  Future<void> _loadAllFavorites() async {
    final breakfastFavs = await FavoritesManager.getFavoriteMeals('breakfast');
    final lunchFavs = await FavoritesManager.getFavoriteMeals('lunch');
    final dinnerFavs = await FavoritesManager.getFavoriteMeals('dinner');
    final snackFavs = await FavoritesManager.getFavoriteMeals('snack');
    final workoutFavs = await FavoritesManager.getFavoriteWorkouts();
    final fastingFavs = await FavoritesManager.getFavoriteFasting();

    setState(() {
      _favoriteMealsBreakfast = breakfastFavs;
      _favoriteMealsLunch = lunchFavs;
      _favoriteMealsDinner = dinnerFavs;
      _favoriteMealsSnack = snackFavs;
      _favoriteWorkouts = workoutFavs;
      _favoriteFasting = fastingFavs;
    });
  }

  void _showAddCustomMealDialog(String mealType) {
    String customMeal = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Custom $mealType'),
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
            onPressed: () async {
              if (customMeal.trim().isNotEmpty) {
                await FavoritesManager.toggleFavoriteMeal(customMeal, mealType);
                Navigator.pop(context);
                _loadAllFavorites();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add & Favorite'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomWorkoutDialog() {
    String customWorkout = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Workout'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g., Morning run',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (value) => customWorkout = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (customWorkout.trim().isNotEmpty) {
                await FavoritesManager.toggleFavoriteWorkout(customWorkout);
                Navigator.pop(context);
                _loadAllFavorites();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add & Favorite'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomFastingDialog() {
    String customName = '';
    int selectedHours = 14;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Custom Fasting Window'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g., Morning fast, OMAD',
                  labelText: 'Name (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (value) => customName = value,
              ),
              const SizedBox(height: 20),
              Text(
                'Duration: $selectedHours hours',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Slider(
                value: selectedHours.toDouble(),
                min: 8,
                max: 36,
                divisions: 28,
                onChanged: (value) {
                  setState(() => selectedHours = value.toInt());
                },
                activeColor: Colors.blue.shade400,
                label: '$selectedHours h',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  customName.isEmpty
                      ? '$selectedHours-hour fast'
                      : '$customName ($selectedHours-hour fast)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final fastingLabel = customName.isEmpty
                    ? '$selectedHours-hour fast'
                    : '$customName ($selectedHours-hour fast)';
                await FavoritesManager.toggleFavoriteFasting(fastingLabel);
                Navigator.pop(context);
                _loadAllFavorites();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add & Favorite'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteMealsList(String mealType, Set<String> favorites) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (favorites.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No favorite ${mealType.toLowerCase()}s yet',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                String meal = favorites.toList()[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                        GestureDetector(
                          onTap: () async {
                            await FavoritesManager.toggleFavoriteMeal(meal, mealType);
                            _loadAllFavorites();
                          },
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddCustomMealDialog(mealType),
              icon: const Icon(Icons.add),
              label: Text('Add Custom ${mealType.capitalize()}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteWorkoutsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_favoriteWorkouts.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No favorite workouts yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: _favoriteWorkouts.length,
              itemBuilder: (context, index) {
                String workout = _favoriteWorkouts.toList()[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            workout,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await FavoritesManager.toggleFavoriteWorkout(workout);
                            _loadAllFavorites();
                          },
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddCustomWorkoutDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade400,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteFastingList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_favoriteFasting.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No favorite fasting windows yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: _favoriteFasting.length,
              itemBuilder: (context, index) {
                String fasting = _favoriteFasting.toList()[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            fasting,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await FavoritesManager.toggleFavoriteFasting(fasting);
                            _loadAllFavorites();
                          },
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddCustomFastingDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Fasting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade400,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            '📚 My Database',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.red,
            labelColor: const Color(0xFF333333),
            unselectedLabelColor: const Color(0xFF999999),
            tabs: const [
              Tab(text: '🌅 Breakfast'),
              Tab(text: '🍽️ Lunch'),
              Tab(text: '🌙 Dinner'),
              Tab(text: '🍿 Snack'),
              Tab(text: '💪 Workouts'),
              Tab(text: '⏱️ Fasting'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFavoriteMealsList('breakfast', _favoriteMealsBreakfast),
            _buildFavoriteMealsList('lunch', _favoriteMealsLunch),
            _buildFavoriteMealsList('dinner', _favoriteMealsDinner),
            _buildFavoriteMealsList('snack', _favoriteMealsSnack),
            _buildFavoriteWorkoutsList(),
            _buildFavoriteFastingList(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

extension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
