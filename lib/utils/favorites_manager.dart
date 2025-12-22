import 'package:shared_preferences/shared_preferences.dart';

class FavoritesManager {
  // Meal keys by type
  static String _getMealKey(String mealType) => 'favorite_meals_$mealType';
  static const String _workoutsKey = 'favorite_workouts';
  static const String _fastingKey = 'favorite_fasting';

  // Load favorite meals by meal type
  static Future<Set<String>> getFavoriteMeals(String mealType) async {
    final prefs = await SharedPreferences.getInstance();
    final favStr = prefs.getString(_getMealKey(mealType)) ?? '';
    if (favStr.isEmpty) return {};
    return favStr.split(',').toSet();
  }

  // Load favorite workouts
  static Future<Set<String>> getFavoriteWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final favStr = prefs.getString(_workoutsKey) ?? '';
    if (favStr.isEmpty) return {};
    return favStr.split(',').toSet();
  }

  // Load favorite fasting
  static Future<Set<String>> getFavoriteFasting() async {
    final prefs = await SharedPreferences.getInstance();
    final favStr = prefs.getString(_fastingKey) ?? '';
    if (favStr.isEmpty) return {};
    return favStr.split(',').toSet();
  }

  // Toggle favorite meal by meal type
  static Future<void> toggleFavoriteMeal(String meal, String mealType) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteMeals(mealType);
    if (favorites.contains(meal)) {
      favorites.remove(meal);
    } else {
      favorites.add(meal);
    }
    await prefs.setString(_getMealKey(mealType), favorites.join(','));
  }

  // Toggle favorite workout
  static Future<void> toggleFavoriteWorkout(String workout) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteWorkouts();
    if (favorites.contains(workout)) {
      favorites.remove(workout);
    } else {
      favorites.add(workout);
    }
    await prefs.setString(_workoutsKey, favorites.join(','));
  }

  // Toggle favorite fasting
  static Future<void> toggleFavoriteFasting(String fasting) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteFasting();
    if (favorites.contains(fasting)) {
      favorites.remove(fasting);
    } else {
      favorites.add(fasting);
    }
    await prefs.setString(_fastingKey, favorites.join(','));
  }

  // Check if item is favorite
  static Future<bool> isFavoriteMeal(String meal, String mealType) async {
    final favorites = await getFavoriteMeals(mealType);
    return favorites.contains(meal);
  }

  static Future<bool> isFavoriteWorkout(String workout) async {
    final favorites = await getFavoriteWorkouts();
    return favorites.contains(workout);
  }

  static Future<bool> isFavoriteFasting(String fasting) async {
    final favorites = await getFavoriteFasting();
    return favorites.contains(fasting);
  }
}
