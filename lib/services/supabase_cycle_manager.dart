import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

class Cycle {
  final String id;
  final String userId;
  final int cycleLength;
  final int periodLength;
  final DateTime startDate;
  final DateTime createdAt;

  Cycle({
    required this.id,
    required this.userId,
    required this.cycleLength,
    required this.periodLength,
    required this.startDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'cycle_length': cycleLength,
      'period_length': periodLength,
      'start_date': startDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Cycle.fromMap(Map<String, dynamic> map) {
    return Cycle(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      cycleLength: map['cycle_length'] as int? ?? 28,
      periodLength: map['period_length'] as int? ?? 5,
      startDate: DateTime.parse(map['start_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Calculate current day in cycle
  int getCurrentDay() {
    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;
    return (difference % cycleLength) + 1;
  }

  // Calculate next cycle start date
  DateTime getNextCycleStart() {
    return startDate.add(Duration(days: cycleLength));
  }

  // Get days remaining in current phase
  int getDaysInCurrentPhase(String phaseType) {
    final phaseMap = getPhaseRange();
    if (!phaseMap.containsKey(phaseType)) return 0;

    final range = phaseMap[phaseType]!;
    final currentDay = getCurrentDay();

    if (currentDay < (range['start'] ?? 0) || currentDay > (range['end'] ?? 0)) {
      return 0;
    }

    return (range['end'] ?? 0) - currentDay + 1;
  }

  // Get phase range by type (using adaptive cycle calculation with menstrualLength)
  // Formula from PHASE_QUICK_REFERENCE.md:
  // - Menstrual: Day 1 → menstrualLength
  // - Follicular: Day (menstrualLength + 1) → (ovulationDay - 2)
  // - Ovulation: Day (ovulationDay - 2) → (ovulationDay + 2) [5-day Manifestation window]
  // Phase boundaries from new adaptive table:
  // - Menstrual: Day 1 → periodLength
  // - Follicular: Day (periodLength + 1) → (ovulationDay - 2)
  // - Ovulation: Day (ovulationDay - 1) → (ovulationDay + 1)
  // - Early Luteal: Day (ovulationDay + 2) → (ovulationDay + 5)
  // - Late Luteal: Day (ovulationDay + 6) → cycleLength
  // Where: ovulationDay = cycleLength - 14
  Map<String, Map<String, int>> getPhaseRange() {
    // Calculate ovulation day using fixed luteal length (14 days)
    final ovulationDay = cycleLength - 14;
    
    return {
      'menstrual': {'start': 1, 'end': periodLength},
      'follicular': {'start': periodLength + 1, 'end': ovulationDay - 2},
      'ovulatory': {'start': ovulationDay - 1, 'end': ovulationDay + 1},
      'early_luteal': {'start': ovulationDay + 2, 'end': ovulationDay + 5},
      'luteal': {'start': ovulationDay + 6, 'end': cycleLength},
    };
  }

  // Get current phase type
  String getCurrentPhaseType() {
    final currentDay = getCurrentDay();
    final ranges = getPhaseRange();

    for (final entry in ranges.entries) {
      final range = entry.value;
      if (currentDay >= range['start']! && currentDay <= range['end']!) {
        return entry.key;
      }
    }

    return 'menstrual'; // fallback
  }
}

class Phase {
  final String id;
  final String cycleId;
  final String phaseType;
  final int startDay;
  final int endDay;
  final DateTime createdAt;

  Phase({
    required this.id,
    required this.cycleId,
    required this.phaseType,
    required this.startDay,
    required this.endDay,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cycle_id': cycleId,
      'phase_type': phaseType,
      'start_day': startDay,
      'end_day': endDay,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Phase.fromMap(Map<String, dynamic> map) {
    return Phase(
      id: map['id'] as String,
      cycleId: map['cycle_id'] as String,
      phaseType: map['phase_type'] as String,
      startDay: map['start_day'] as int,
      endDay: map['end_day'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class SupabaseCycleManager {
  static const String _cyclesTable = 'cycles';
  static const String _phasesTable = 'phases';

  // Get user's current cycle
  static Future<Cycle?> getCurrentCycle(String userId) async {
    try {
      final data = await SupabaseService.fetchData(
        _cyclesTable,
        userId: userId,
      );

      if (data.isEmpty) return null;

      // Return the most recent cycle
      data.sort((a, b) =>
          DateTime.parse(b['created_at'] as String)
              .compareTo(DateTime.parse(a['created_at'] as String)));

      return Cycle.fromMap(data.first);
    } catch (e) {
      print('Error getting current cycle: $e');
      return null;
    }
  }

  // Get all cycles for a user
  static Future<List<Cycle>> getAllCycles(String userId) async {
    try {
      final data = await SupabaseService.fetchData(
        _cyclesTable,
        userId: userId,
      );

      return data.map((item) => Cycle.fromMap(item)).toList();
    } catch (e) {
      print('Error getting all cycles: $e');
      return [];
    }
  }

  // Alias for getAllCycles for backward compatibility
  static Future<List<Cycle>> getUserCycles(String userId) async {
    return getAllCycles(userId);
  }

  // Create new cycle
  static Future<Cycle?> createCycle({
    required String userId,
    required DateTime startDate,
    required int cycleLength,
    required int periodLength,
  }) async {
    try {
      final cycle = Cycle(
        id: const Uuid().v4(),
        userId: userId,
        cycleLength: cycleLength,
        periodLength: periodLength,
        startDate: startDate,
        createdAt: DateTime.now(),
      );

      await SupabaseService.insertData(_cyclesTable, cycle.toMap());

      // Auto-create phases for this cycle
      await _createPhasesForCycle(cycle);

      return cycle;
    } catch (e) {
      print('Error creating cycle: $e');
      return null;
    }
  }

  // Update existing cycle
  static Future<void> updateCycle(Cycle cycle) async {
    try {
      await SupabaseService.updateData(
        _cyclesTable,
        cycle.id,
        cycle.toMap(),
      );
    } catch (e) {
      print('Error updating cycle: $e');
    }
  }

  // Delete cycle
  static Future<void> deleteCycle(String cycleId) async {
    try {
      await SupabaseService.deleteData(_cyclesTable, cycleId);
    } catch (e) {
      print('Error deleting cycle: $e');
    }
  }

  // Get phases for a cycle
  static Future<List<Phase>> getPhases(String cycleId) async {
    try {
      final data = await SupabaseService.fetchData(
        _phasesTable,
        filters: {'cycle_id': cycleId},
      );

      return data.map((item) => Phase.fromMap(item)).toList();
    } catch (e) {
      print('Error getting phases: $e');
      return [];
    }
  }

  // Get current phase for a cycle
  static Future<Phase?> getCurrentPhase(String cycleId) async {
    try {
      final cycle = await SupabaseService.fetchSingleRecord(
        _cyclesTable,
        cycleId,
      );

      if (cycle == null) return null;

      final cycleObj = Cycle.fromMap(cycle);
      final currentPhaseType = cycleObj.getCurrentPhaseType();

      final phases = await getPhases(cycleId);
      final phase = phases.firstWhere(
        (p) => p.phaseType == currentPhaseType,
        orElse: () => phases.first,
      );

      return phase;
    } catch (e) {
      print('Error getting current phase: $e');
      return null;
    }
  }

  // Get cycle with real-time updates
  // Get cycle stream for real-time updates
  // TODO: Implement real-time stream when Supabase library is updated
  // static Stream<Cycle?> getCycleStream(String userId) {
  //   return SupabaseService.subscribeToTable(
  //     _cyclesTable,
  //     userId: userId,
  //   ).map((data) {
  //     if (data.isEmpty) return null;
  //
  //     data.sort((a, b) =>
  //         DateTime.parse(b['created_at'] as String)
  //             .compareTo(DateTime.parse(a['created_at'] as String)));
  //
  //     return Cycle.fromMap(data.first);
  //   });
  // }

  // Private: Create phases for a cycle (called automatically)
  static Future<void> _createPhasesForCycle(Cycle cycle) async {
    try {
      final phaseRanges = cycle.getPhaseRange();

      for (final entry in phaseRanges.entries) {
        final phase = Phase(
          id: const Uuid().v4(),
          cycleId: cycle.id,
          phaseType: entry.key,
          startDay: entry.value['start']!,
          endDay: entry.value['end']!,
          createdAt: DateTime.now(),
        );

        await SupabaseService.insertData(_phasesTable, phase.toMap());
      }
    } catch (e) {
      print('Error creating phases: $e');
    }
  }
}
