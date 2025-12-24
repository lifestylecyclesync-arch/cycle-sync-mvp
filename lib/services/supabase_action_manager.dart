import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

class Action {
  final String id;
  final String phaseId;
  final String category;
  final String description;
  final DateTime createdAt;

  Action({
    required this.id,
    required this.phaseId,
    required this.category,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phase_id': phaseId,
      'category': category,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Action.fromMap(Map<String, dynamic> map) {
    return Action(
      id: map['id'] as String,
      phaseId: map['phase_id'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class SupabaseActionManager {
  static const String _table = 'actions';

  // Get all actions for a phase
  static Future<List<Action>> getActionsForPhase(String phaseId) async {
    try {
      final data = await SupabaseService.fetchData(
        _table,
        filters: {'phase_id': phaseId},
      );

      return data.map((item) => Action.fromMap(item)).toList();
    } catch (e) {
      print('Error getting actions for phase: $e');
      return [];
    }
  }

  // Get actions by category for a phase
  static Future<List<Action>> getActionsByCategory(
    String phaseId,
    String category,
  ) async {
    try {
      final allActions = await getActionsForPhase(phaseId);
      return allActions.where((a) => a.category == category).toList();
    } catch (e) {
      print('Error getting actions by category: $e');
      return [];
    }
  }

  // Create action
  static Future<Action?> createAction({
    required String phaseId,
    required String category,
    required String description,
  }) async {
    try {
      final action = Action(
        id: const Uuid().v4(),
        phaseId: phaseId,
        category: category,
        description: description,
        createdAt: DateTime.now(),
      );

      await SupabaseService.insertData(_table, action.toMap());
      return action;
    } catch (e) {
      print('Error creating action: $e');
      return null;
    }
  }

  // Delete action
  static Future<void> deleteAction(String actionId) async {
    try {
      await SupabaseService.deleteData(_table, actionId);
    } catch (e) {
      print('Error deleting action: $e');
    }
  }

  // Get predefined actions for a phase (helper for MVP)
  static List<Action> getPredefinedActionsForPhase(
    String phaseId,
    String phaseType,
  ) {
    final actions = _getPhaseRecommendations(phaseType);
    return actions
        .asMap()
        .entries
        .map((entry) => Action(
              id: const Uuid().v4(),
              phaseId: phaseId,
              category: entry.value['category'] as String,
              description: entry.value['description'] as String,
              createdAt: DateTime.now(),
            ))
        .toList();
  }

  // Private: Phase-specific recommendations
  static List<Map<String, String>> _getPhaseRecommendations(String phaseType) {
    const menstrualActions = [
      {
        'category': 'nutrition',
        'description':
            'Focus on iron-rich foods (spinach, lean red meat, lentils)'
      },
      {
        'category': 'nutrition',
        'description': 'Stay hydrated: drink extra water'
      },
      {
        'category': 'fitness',
        'description': 'Gentle yoga, walking, or stretching'
      },
      {
        'category': 'lifestyle',
        'description': 'Get extra rest and prioritize sleep'
      },
      {
        'category': 'lifestyle',
        'description': 'Use heating pad if experiencing cramps'
      },
    ];

    const follicularActions = [
      {
        'category': 'fitness',
        'description': 'Increase exercise intensity, start strength training'
      },
      {
        'category': 'nutrition',
        'description': 'Eat complex carbs and lean proteins'
      },
      {
        'category': 'lifestyle',
        'description': 'Great time for new projects and social activities'
      },
      {
        'category': 'nutrition',
        'description': 'Increase vegetables and whole grains'
      },
    ];

    const ovatoryActions = [
      {
        'category': 'nutrition',
        'description': 'Keep calories and proteins high'
      },
      {
        'category': 'fitness',
        'description': 'Peak energy: excellent time for intense workouts'
      },
      {
        'category': 'lifestyle',
        'description': 'Best time for important meetings and presentations'
      },
      {
        'category': 'lifestyle',
        'description': 'Higher confidence and motivation period'
      },
    ];

    const lutealActions = [
      {
        'category': 'nutrition',
        'description': 'Increase magnesium (dark chocolate, nuts, seeds)'
      },
      {
        'category': 'nutrition',
        'description': 'More complex carbs to support serotonin'
      },
      {
        'category': 'fitness',
        'description': 'Moderate exercise: yoga, Pilates, swimming'
      },
      {
        'category': 'lifestyle',
        'description': 'Introspection time: journaling, meditation'
      },
      {
        'category': 'lifestyle',
        'description': 'Plan personal time and self-care activities'
      },
    ];

    switch (phaseType) {
      case 'menstrual':
        return menstrualActions;
      case 'follicular':
        return follicularActions;
      case 'ovulatory':
        return ovatoryActions;
      case 'luteal':
        return lutealActions;
      default:
        return [];
    }
  }
}
