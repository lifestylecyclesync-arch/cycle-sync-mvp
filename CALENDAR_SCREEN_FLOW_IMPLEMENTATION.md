# Calendar Screen — Complete Flow with UI + Logic

## Overview
The Calendar Screen now provides a complete tracking experience with daily markers, weekly breakdowns, and monthly summaries. All views persist even after goal deletion, providing a stable user experience.

---

## Complete Flow Implementation

### **1. Entry & Filter Dropdown**

**UI Presentation:**
```
┌─────────────────────────────┐
│ Filter: [📅 Phases ▼]       │
└─────────────────────────────┘
```

**Dropdown Contents:**
- Always: 📅 Phases
- If goals exist: Goal type filters (e.g., 💪 Exercise, 🧘 Meditation)
- If manual filters: Category filters with "(no goal)" label
- Always: [Add category] option

**Implementation:**
```dart
DropdownButton<String>(
  value: _selectedFilter,
  items: [
    const DropdownMenuItem(value: 'phases', child: Text('📅 Phases')),
    // Goal-based filters
    if (_goals.isNotEmpty) ...[
      ..._getUniqueGoalTypes().map((goalType) => 
        DropdownMenuItem(value: 'goal_type_$goalType', ...)
      ),
    ],
    // Manual filters
    if (_manualFilters.isNotEmpty) ...[
      ..._manualFilters.map((goalType) =>
        DropdownMenuItem(...) // with "(no goal)" label
      ),
    ],
    // Add category
    DropdownMenuItem(value: 'add_filter', child: Text('Add category')),
  ],
  onChanged: (value) {
    if (value == 'add_filter') {
      _showAddFilterDialog();
    } else if (value != null && value.isNotEmpty) {
      setState(() => _selectedFilter = value);
    }
  },
)
```

**Logic:**
- ✅ Goal added → Filter appears automatically
- ✅ Goal deleted → Filter persists (switches to "(no goal)" mode)
- ✅ User manually adds → Filter appears with "(no goal)" label
- ✅ User manually removes → Filter disappears
- ✅ Persists to SharedPreferences via `_saveManualFilters()`

---

### **2. Daily Grid (Month View)**

**UI Presentation:**
```
PHASES VIEW (default):
┌────┬────┬────┬────┬────┬────┬────┐
│ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │ 7  │  (day numbers)
├────┼────┼────┼────┼────┼────┼────┤
│    │    │    │    │    │    │    │
└────┴────┴────┴────┴────┴────┴────┘

GOAL VIEW (e.g., 💪 Exercise):
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│ ✓   │ ○   │ ✓   │ ○   │ ✓   │ ○   │ ○   │  (✓ = completed, ○ = not)
├─────┼─────┼─────┼─────┼─────┼─────┼─────┤
│ ✓   │ ✓   │ ○   │ ✓   │ ○   │ ○   │ ✓   │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┘
```

**Implementation:**
```dart
calendarBuilders: CalendarBuilders(
  defaultBuilder: (context, day, focusedDay) {
    bool isGoalCompleted = false;
    
    if (_selectedFilter.startsWith('goal_type_')) {
      final goalType = _selectedFilter.replaceFirst('goal_type_', '');
      final goalsOfType = _goals.where((g) => g.type == goalType).toList();
      final dateKey = DateTime(day.year, day.month, day.day);
      
      for (final goal in goalsOfType) {
        if (_goalCompletions[goal.id]?[dateKey] ?? false) {
          isGoalCompleted = true;
          break;
        }
      }
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _getFilteredDayColor(day)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_selectedFilter.startsWith('goal_type_')) ...[
            if (isGoalCompleted)
              const Icon(Icons.check_circle, color: Colors.white, size: 16)
            else
              Icon(Icons.circle_outlined, color: Colors.white.withValues(alpha: 0.6), size: 14)
          ] else
            Text('${day.day}', style: const TextStyle(color: Color(0xFF333333))),
        ],
      ),
    );
  },
),
```

**Logic:**
- **Phases view**: Shows day numbers, colors indicate cycle phase
- **Goal view**: Shows completion markers (✓ for completed, ○ for not)
- ✅ Tap day → Opens Day Details Modal
- ✅ Completion based on `_goalCompletions[goalId][dateKey]`
- ✅ If no goal exists: No markers shown, manual tracking only

---

### **3. Weekly Summary Card**

**UI Presentation:**
```
┌─────────────────────────────────────┐
│ Weekly Breakdown                    │
├─────────────────────────────────────┤
│ Week 1                    3/3  100% ↑│
│ Week 2                    2/3   67% ↓│
│ Week 3                    4/3  133% ↑│
│ Week 4                    3/3  100% →│
└─────────────────────────────────────┘
```

**Implementation:**
```dart
Widget _buildWeeklySummaryCard() {
  final weeklySummaries = _getWeeklySummaries();
  
  if (weeklySummaries.isEmpty) return const SizedBox.shrink();
  
  return Card(
    color: Colors.amber.shade50,
    child: Column(
      children: [
        const Text('Weekly Breakdown'),
        ...weeklySummaries.asMap().entries.map((entry) {
          final week = entry.value;
          final percentage = week['percentage'] as int;
          final trend = _getTrendIndicator(percentage, 
            entry.key > 0 ? weeklySummaries[entry.key - 1]['percentage'] : 0);
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Week ${week['week']}'),
              Text('${week['completed']}/${week['target']}'),
              Row(children: [
                Text('$percentage%'),
                Text(trend), // ↑ ↓ →
              ]),
            ],
          );
        }),
      ],
    ),
  );
}

List<Map<String, dynamic>> _getWeeklySummaries() {
  if (_selectedFilter == 'phases') return [];
  
  final goalType = _selectedFilter.replaceFirst('goal_type_', '');
  final goalsOfType = _goals.where((g) => g.type == goalType).toList();
  if (goalsOfType.isEmpty) return [];
  
  final weekSummaries = <Map<String, dynamic>>[];
  // Calculate for each week of current month
  // ...
  return weekSummaries;
}
```

**Logic:**
- ✅ Shows all weeks in current month
- ✅ Calculates completions vs. target frequency
- ✅ Shows percentage (can exceed 100% if over-achieved)
- ✅ Trend indicators: ↑ (improving), ↓ (declining), → (same)
- ✅ Only shows for goal-based filters (not phases)
- ✅ If no goal: Hides card

---

### **4. Monthly Summary Card**

**UI Presentation:**
```
┌────────────────────────────────────┐
│ Monthly Summary          🎉        │
├────────────────────────────────────┤
│ Total Progress      Completion Rate│
│      9/12                  75%     │
│ ████████░░░░░░░░░░░░░░░░░░ (bar)  │
├────────────────────────────────────┤
│ Highlights:                        │
│ ✨ Best week: Week 3 (4 completions)
│ ⚠️  Missed week: Week 2 (below target)
│ 🚀 Over-achieved: Week 3 (exceeded) │
└────────────────────────────────────┘
```

**Implementation:**
```dart
Widget _buildMonthlySummaryCard() {
  final weeklySummaries = _getWeeklySummaries();
  if (weeklySummaries.isEmpty) return const SizedBox.shrink();
  
  int totalCompleted = 0, totalTarget = 0;
  int bestWeekNum = 0, bestWeekCompleted = 0;
  int missedWeekNum = 0, overAchievedWeekNum = 0;
  
  for (final week in weeklySummaries) {
    totalCompleted += week['completed'] as int;
    totalTarget += week['target'] as int;
    
    if ((week['completed'] as int) > bestWeekCompleted) {
      bestWeekCompleted = week['completed'] as int;
      bestWeekNum = week['week'] as int;
    }
    
    if ((week['percentage'] as int) < 100 && missedWeekNum == 0) {
      missedWeekNum = week['week'] as int;
    }
    
    if ((week['percentage'] as int) > 100 && overAchievedWeekNum == 0) {
      overAchievedWeekNum = week['week'] as int;
    }
  }
  
  final monthlyPercentage = totalTarget > 0 
    ? ((totalCompleted / totalTarget) * 100).toInt() 
    : 0;
  final isGoalAchieved = monthlyPercentage >= 100;
  
  return Card(
    color: Colors.purple.shade50,
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Monthly Summary'),
            if (isGoalAchieved) const Text('🎉 Goal Achieved!'),
          ],
        ),
        // Main stats: Total / Percentage
        // Progress bar
        // Highlights section
      ],
    ),
  );
}
```

**Logic:**
- ✅ Aggregates all weekly data into monthly totals
- ✅ Shows total completions vs. target
- ✅ Shows monthly percentage completion
- ✅ Displays badge "🎉 Goal Achieved!" if >= 100%
- ✅ Highlights:
  - **Best week**: Week with most completions
  - **Missed week**: First week below target
  - **Over-achieved**: Week that exceeded target
- ✅ Progress bar shows overall completion

---

### **5. Persistence & Sync**

**Persistence:**
```dart
// Load manual filters on init and return from other screens
Future<void> _loadManualFilters() async {
  final prefs = await SharedPreferences.getInstance();
  final manualFiltersJson = prefs.getString('calendar_manual_filters') ?? '';
  // Parse comma-separated list
}

// Save when user adds/removes
Future<void> _saveManualFilters() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('calendar_manual_filters', _manualFilters.join(','));
}
```

**Sync Pattern:**
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _loadManualFilters(); // Refresh manual filters
  _loadGoals();         // Reload goals from GoalManager
}
```

**Manual Add:**
```dart
void _addManualFilter(String goalType) async {
  setState(() => _manualFilters.add(goalType));
  await _saveManualFilters();
}
```

**Manual Remove:**
```dart
void _removeFilter(String goalType) async {
  setState(() {
    _manualFilters.remove(goalType);
    if (_selectedFilter == 'goal_type_$goalType') {
      _selectedFilter = 'phases'; // Reset if viewing
    }
  });
  await _saveManualFilters();
}
```

**Goal Deletion Behavior:**
- Goal deleted in Profile → `_loadGoals()` called
- If goal had manual filter: Filter persists as "(no goal)"
- If goal had no manual filter: Filter disappears
- View shows "No active goal set for this category"

---

## Complete User Journey Examples

### **Journey 1: Create Goal → Track Progress**
1. User creates "💪 Exercise 3x/week" in Profile
2. Return to Calendar
3. Filter dropdown now shows: 📅 Phases + 💪 Exercise
4. Select 💪 Exercise
5. Daily grid shows: ✓ (completed), ○ (not completed)
6. Weekly Summary shows: Week 1: 3/3 100% ↑
7. Monthly Summary shows: 9/12 75%, Best week = Week 3

### **Journey 2: Manual Add → Later Set Goal**
1. User opens Calendar → only Phases visible
2. Taps "Add category" → adds 💧 Water manually
3. Filter dropdown shows: 📅 Phases + 💧 Water (no goal)
4. Select 💧 Water → shows "No active goal" message
5. User sets "💧 Water 2L/day" in Profile
6. Return to Calendar
7. 💧 Water now tracks completions with progress metrics

### **Journey 3: Goal Deletion → View Persists**
1. User has "💪 Exercise" goal being tracked
2. User deletes goal in Profile
3. Return to Calendar
4. 💪 Exercise still in dropdown (if was manual) OR disappears (if goal-only)
5. If persists: Shows "No active goal" message
6. User can set new "💪 Exercise" goal → tracking resumes

---

## Data Structure

### **State Variables:**
```dart
String _selectedFilter = 'phases';
List<Goal> _goals = [];
Set<String> _manualFilters = {};
Map<String, Map<DateTime, bool>> _goalCompletions = {};
```

### **Weekly Summary Structure:**
```dart
{
  'week': 1,           // Week number (1-4)
  'completed': 3,      // Completions this week
  'target': 3,         // Target frequency
  'percentage': 100,   // Percentage (can be >100)
  'startDate': DateTime,
  'endDate': DateTime,
}
```

### **Monthly Summary Calculation:**
```dart
totalCompleted = sum of all weekly completions
totalTarget = sum of all weekly targets
monthlyPercentage = (totalCompleted / totalTarget) * 100
highlights = {
  bestWeek: week with highest completions,
  missedWeek: first week below target,
  overAchievedWeek: first week over target,
}
```

---

## Visual Indicators

| Element | Meaning |
|---------|---------|
| ✓ | Goal completed on this day |
| ○ | Goal not completed on this day |
| ↑ | Progress improved from previous week |
| ↓ | Progress declined from previous week |
| → | Progress same as previous week |
| 🎉 | Monthly goal achieved (>=100%) |
| ✨ | Best performing week |
| ⚠️ | Week below target |
| 🚀 | Week exceeded target |

---

## Testing Checklist

- [ ] Phases view shows day numbers
- [ ] Goal view shows completion markers (✓ ○)
- [ ] Weekly Summary shows for goal filters only
- [ ] Monthly Summary shows for goal filters only
- [ ] Trend indicators calculate correctly (↑ ↓ →)
- [ ] Manual filter persists after goal deletion
- [ ] Manual filter removed → view disappears
- [ ] Set goal for manual filter → becomes tracked
- [ ] SharedPreferences saves manual filters
- [ ] Switch between filters → view updates
- [ ] Empty state → only Phases visible
- [ ] Goal achieved badge → shows at 100%+
- [ ] Best week highlight → correct week

---

## Summary

The Calendar Screen now provides:
✅ **Daily Grid**: Visual completion markers (✓ ○) for goal tracking
✅ **Weekly Summary**: Per-week progress with trend indicators
✅ **Monthly Summary**: Aggregated statistics with highlights
✅ **Persistent Views**: Manual filters persist even after goal deletion
✅ **Seamless Sync**: Add/Edit/Delete in Goals Module updates instantly
✅ **No Surprises**: Views never disappear unexpectedly
✅ **Clear Guidance**: "(no goal)" label shows manual vs. goal-based views
