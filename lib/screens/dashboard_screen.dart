import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../widgets/gradient_wrapper.dart';
import '../utils/cycle_utils.dart';
import '../models/phase.dart' as phase_model;
import '../utils/goal_manager.dart' as util_goal;
import '../utils/goal_manager.dart' show Goal;
import '../utils/avatar_manager.dart';
import '../utils/auth_guard.dart';
import '../services/supabase_cycle_manager.dart' as supabase_cycle;
import '../services/supabase_goal_manager.dart' as supabase_goal;
import 'profile_screen.dart';
import 'calendar_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Cycle data
  late DateTime _lastPeriodStart;
  late int _cycleLength;
  bool _isLoading = true;
  List<Goal> _goals = [];
  int _avatarRefreshKey = 0; // Trigger FutureBuilder refresh
  bool _skipRecoveryDismissed = false; // Track skip recovery banner dismissal
  int _appLaunchCount = 0; // Track app launches for banner resurfacing

  @override
  void initState() {
    super.initState();
    _loadCycleData();
    _loadGoals();
    _loadBannerState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh avatar and goals when returning to this screen
    setState(() {
      _avatarRefreshKey++;
    });
    _loadGoals(); // Reload goals when coming back from profile
  }

  Future<void> _loadBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDismissalDate = prefs.getString('skipRecoveryDismissedDate');
    final dismissalCount = prefs.getInt('skipRecoveryDismissalCount') ?? 0;
    
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    // Reset dismissal on new cycle or after 3-5 launches
    if (lastDismissalDate == null || lastDismissalDate != todayKey || dismissalCount >= 3) {
      setState(() {
        _skipRecoveryDismissed = false;
        _appLaunchCount = 0;
      });
    } else {
      setState(() {
        _skipRecoveryDismissed = true;
        _appLaunchCount = dismissalCount;
      });
    }
  }

  Future<void> _dismissSkipRecoveryBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    await prefs.setString('skipRecoveryDismissedDate', todayKey);
    await prefs.setInt('skipRecoveryDismissalCount', _appLaunchCount + 1);
    
    setState(() {
      _skipRecoveryDismissed = true;
      _appLaunchCount++;
    });
  }

  Future<void> _loadCycleData() async {
    try {
      // If user is logged in, try to load from Supabase
      if (AuthGuard.isLoggedIn()) {
        final userId = AuthGuard.getCurrentUserId();
        if (userId != null) {
          final cycles = await supabase_cycle.SupabaseCycleManager.getUserCycles(userId);
          if (cycles.isNotEmpty) {
            // Use the most recent cycle
            final latestCycle = cycles.last;
            setState(() {
              _lastPeriodStart = latestCycle.startDate;
              _cycleLength = latestCycle.cycleLength;
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      print('Error loading cycle from Supabase: $e');
      // Fall through to load from local storage
    }

    // Fall back to local storage
    final prefs = await SharedPreferences.getInstance();

    String? lastPeriodStr = prefs.getString('lastPeriodStart');
    _lastPeriodStart = lastPeriodStr != null
        ? DateTime.parse(lastPeriodStr)
        : DateTime(2024, 11, 28);

    _cycleLength = prefs.getInt('cycleLength') ?? 28;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadGoals() async {
    try {
      // If user is logged in, try to load from Supabase
      if (AuthGuard.isLoggedIn()) {
        final userId = AuthGuard.getCurrentUserId();
        if (userId != null) {
          final supabaseGoals = await supabase_goal.SupabaseGoalManager.getAllGoals(userId);
          if (supabaseGoals.isNotEmpty) {
            // Convert SupabaseGoalManager.Goal to Goal (local model)
            final localGoals = supabaseGoals.map((sg) {
              return util_goal.Goal(
                id: sg.id,
                name: _getGoalNameFromType(sg.goalType),
                type: _mapGoalTypeToString(sg.goalType),
                frequency: sg.frequency,
                frequencyValue: 1, // Default, not stored in Supabase schema
                amount: sg.targetValue,
                description: sg.description ?? '',
              );
            }).toList();

            setState(() {
              _goals = localGoals;
            });
            return;
          }
        }
      }
    } catch (e) {
      print('Error loading goals from Supabase: $e');
      // Fall through to load from local storage
    }

    // Fall back to local storage
    final localGoals = await util_goal.GoalManager.getAllGoals();
    setState(() {
      _goals = localGoals;
    });
  }

  int _getCurrentCycleDay() {
    int daysSinceStart = DateTime.now().difference(_lastPeriodStart).inDays;
    return (daysSinceStart % _cycleLength) + 1;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Color _getPastelColor(String initials) {
    final colors = [
      const Color(0xFFFFB3BA), // Pastel pink
      const Color(0xFFFFDFBA), // Pastel peach
      const Color(0xFFFFFABA), // Pastel yellow
      const Color(0xFFBAFFBA), // Pastel green
      const Color(0xFFBAE1FF), // Pastel blue
      const Color(0xFFE0BBE4), // Pastel purple
      const Color(0xFFFFBBE3), // Pastel magenta
    ];
    final hashCode = initials.hashCode;
    return colors[hashCode % colors.length];
  }

  String _getCurrentPhase() {
    return getCyclePhase(_lastPeriodStart, _cycleLength, DateTime.now());
  }

  Color _getPhaseColor(String phase) {
    return getPhaseColor(phase);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GradientWrapper(
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GradientWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cycle Day ${_getCurrentCycleDay()} of $_cycleLength',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getCurrentPhase(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                          await _loadGoals();
                        },
                        child: FutureBuilder<List<Object>>(
                          key: ValueKey(_avatarRefreshKey),
                          future: Future.wait([
                            SharedPreferences.getInstance(),
                            AvatarManager.getSelectedAvatar().then((avatar) => avatar ?? AvatarManager.getDefaultAvatar()),
                          ]),
                          builder: (context, snapshot) {
                            String userName = 'Guest';
                            AvatarOption? avatar;
                            
                            if (snapshot.hasData) {
                              final prefs = snapshot.data![0] as SharedPreferences;
                              avatar = snapshot.data![1] as AvatarOption?;
                              final savedName = prefs.getString('userName') ?? '';
                              userName = savedName.isEmpty ? 'Guest' : savedName;
                            }
                            
                            final initials = _getInitials(userName);
                            final pastelColor = _getPastelColor(initials);
                            
                            if (avatar?.isPhoto == true && avatar?.photoPath != null) {
                              return CircleAvatar(
                                radius: 22,
                                backgroundImage: FileImage(File(avatar!.photoPath!)),
                              );
                            }
                            
                            return CircleAvatar(
                              radius: 22,
                              backgroundColor: avatar?.color ?? pastelColor,
                              child: Text(
                                avatar?.emoji ?? initials,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
                child: Column(
                  children: [
                    // Skip Recovery Banner (dismissible)
                    if (!_skipRecoveryDismissed && _getCurrentPhase() == 'Menstrual')
                      _buildSkipRecoveryBanner(),

                    // Phase Banner
                    _buildPhaseBanner(),
                    const SizedBox(height: 16),

                    // Daily Recommendations
                    _buildDailyRecommendationsCard(),
                    const SizedBox(height: 16),

                    // Goals Section
                    _buildGoalsCard(),
                    const SizedBox(height: 16),

                    // Phase Progress Circle
                    _buildPhaseProgressCard(),
                    const SizedBox(height: 16),

                    // Phase Details
                    _buildPhaseDetailsCard(),
                    const SizedBox(height: 16),

                    // Cycle Phase Graph
                    _buildCyclePhaseGraph(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Skip Recovery Banner
  Widget _buildSkipRecoveryBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(left: BorderSide(color: Colors.amber.shade400, width: 3)),
      ),
      child: Row(
        children: [
          const Text('🛌', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prioritize Recovery',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Get extra rest and hydration.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _dismissSkipRecoveryBanner,
            child: Icon(
              Icons.close,
              color: Colors.grey.shade600,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // Phase Banner
  Widget _buildPhaseBanner() {
    phase_model.Phase? phase = phase_model.CyclePhases.findPhaseByName(_getCurrentPhase());

    if (phase == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _showTodayDetail,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Text(
              phase.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCurrentPhase(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phase.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // Daily Recommendations
  Widget _buildDailyRecommendationsCard() {
    phase_model.Phase? phase = phase_model.CyclePhases.findPhaseByName(_getCurrentPhase());

    if (phase == null) return const SizedBox.shrink();

    final recommendations = [
      {'emoji': '🍎', 'title': 'Nutrition', 'value': phase.dietName},
      {'emoji': '🏋️', 'title': 'Fitness', 'value': phase.workoutName},
      {'emoji': '⏱️', 'title': 'Fasting', 'value': phase.fastingType},
    ];

    return GestureDetector(
      onTap: _showTodayDetail,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Recommendations',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: recommendations
                  .asMap()
                  .entries
                  .map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> rec = entry.value;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < recommendations.length - 1 ? 8 : 0,
                      ),
                      child: Row(
                        children: [
                          Text(
                            rec['emoji'] as String,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rec['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                                Text(
                                  rec['value'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Navigate to Daily Detail Screen for today
  void _showTodayDetail() {
    // Navigate to Calendar screen to view today's detailed insights
    // The calendar screen will handle opening the daily detail modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CalendarScreen(),
      ),
    );
  }

  Widget _buildPhaseProgressCard() {
    int currentDay = _getCurrentCycleDay();
    double progress = currentDay / _cycleLength;
    phase_model.Phase? phase = phase_model.CyclePhases.findPhaseByName(_getCurrentPhase());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cycle Progress',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (phase != null)
                    Text(
                      phase.getDayRange(_cycleLength),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              Text(
                phase?.emoji ?? '🌙',
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_getPhaseColor(_getCurrentPhase())),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day $currentDay of $_cycleLength',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
              Text(
                '${(_cycleLength - currentDay)} days left',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseDetailsCard() {
    phase_model.Phase? phase = phase_model.CyclePhases.findPhaseByName(_getCurrentPhase());

    if (phase == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phase Details',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailRow('🍎', 'Nutrition', phase.dietName),
          const SizedBox(height: 8),
          _buildDetailRow('🏋️', 'Fitness', phase.workoutName),
          const SizedBox(height: 8),
          _buildDetailRow('⏱️', 'Fasting', phase.fastingType),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCyclePhaseGraph() {
    int currentDay = _getCurrentCycleDay();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hormonal Cycle',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: HormonalCurvePainter(
                cycleLength: _cycleLength,
                currentDay: currentDay,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPhaseLabel('Menstrual', '1-5', _getPhaseColor('Menstrual')),
              _buildPhaseLabel('Follicular', '6-12', _getPhaseColor('Follicular')),
              _buildPhaseLabel('Ovulation', '13-15', _getPhaseColor('Ovulation')),
              _buildPhaseLabel('Luteal', '16-28', _getPhaseColor('Luteal')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseLabel(String name, String days, Color color) {
    return Column(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        Text(
          days,
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goals ${_goals.isNotEmpty ? '(${_goals.length})' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(openGoalDialog: true),
                    ),
                  );
                  await _loadGoals();
                },
                child: const Icon(Icons.add, size: 20, color: Color(0xFF666666)),
              ),
            ],
          ),
          if (_goals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No goals yet • Tap + to add',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            ..._goals.take(3).map((goal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                          if (goal.amount.isNotEmpty)
                            Text(
                              goal.amount,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, size: 16, color: Colors.grey.shade400),
                  ],
                ),
              );
            }).toList(),
            if (_goals.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+${_goals.length - 3} more',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Get goal display name from GoalType
  String _getGoalNameFromType(supabase_goal.GoalType type) {
    final typeStr = _mapGoalTypeToString(type);
    return '${typeStr[0].toUpperCase()}${typeStr.substring(1)}';
  }

  /// Convert SupabaseGoalManager.GoalType enum to string
  String _mapGoalTypeToString(supabase_goal.GoalType type) {
    switch (type) {
      case supabase_goal.GoalType.fitness:
        return 'exercise';
      case supabase_goal.GoalType.hydration:
        return 'water';
      case supabase_goal.GoalType.sleep:
        return 'sleep';
      case supabase_goal.GoalType.meditation:
        return 'meditation';
      case supabase_goal.GoalType.nutrition:
        return 'nutrition';
      case supabase_goal.GoalType.wellness:
      default:
        return 'wellness';
    }
  }
}

class HormonalCurvePainter extends CustomPainter {
  final int cycleLength;
  final int currentDay;

  HormonalCurvePainter({
    required this.cycleLength,
    required this.currentDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 30.0;
    final graphWidth = size.width - (padding * 2);
    final graphHeight = size.height - (padding * 2);
    final startX = padding;
    final startY = padding;

    // Draw phase backgrounds
    final menstrualEnd = (5 / cycleLength) * graphWidth;
    final follicularEnd = (12 / cycleLength) * graphWidth;
    final ovulationEnd = (15 / cycleLength) * graphWidth;

    _drawPhaseBackground(canvas, startX, startY, menstrualEnd, graphHeight, Color(0xFFFFE8E8));
    _drawPhaseBackground(canvas, startX + menstrualEnd, startY, follicularEnd - menstrualEnd, graphHeight, Color(0xFFFFF5E1));
    _drawPhaseBackground(canvas, startX + follicularEnd, startY, ovulationEnd - follicularEnd, graphHeight, Color(0xFFFFF0F7));
    _drawPhaseBackground(canvas, startX + ovulationEnd, startY, graphWidth - ovulationEnd, graphHeight, Color(0xFFF5F0FF));

    // Draw grid lines
    for (int i = 1; i < 4; i++) {
      final y = startY + (graphHeight * i / 4);
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + graphWidth, y),
        Paint()
          ..color = Colors.grey.shade200
          ..strokeWidth = 0.5,
      );
    }

    // Draw phase dividers
    for (final x in [menstrualEnd, follicularEnd, ovulationEnd]) {
      canvas.drawLine(
        Offset(startX + x, startY),
        Offset(startX + x, startY + graphHeight),
        Paint()
          ..color = Colors.grey.shade300
          ..strokeWidth = 1,
      );
    }

    // Draw curves with smooth bezier paths
    _drawSmoothCurve(
      canvas,
      startX,
      startY,
      graphWidth,
      graphHeight,
      _getEstrogen,
      Color(0xFFE91E63),
      'Estrogen',
    );

    _drawSmoothCurve(
      canvas,
      startX,
      startY,
      graphWidth,
      graphHeight,
      _getProgesterone,
      Color(0xFFFFA500),
      'Progesterone',
    );

    // Draw current day vertical line
    final currentX = startX + (currentDay / cycleLength) * graphWidth;
    canvas.drawLine(
      Offset(currentX, startY),
      Offset(currentX, startY + graphHeight),
      Paint()
        ..color = Color(0xFF333333).withValues(alpha: 0.4)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Draw axes
    canvas.drawLine(
      Offset(startX, startY + graphHeight),
      Offset(startX + graphWidth, startY + graphHeight),
      Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 1.5,
    );

    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX, startY + graphHeight),
      Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 1.5,
    );
  }

  void _drawPhaseBackground(Canvas canvas, double x, double y, double width, double height, Color color) {
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, height),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawSmoothCurve(
    Canvas canvas,
    double startX,
    double startY,
    double graphWidth,
    double graphHeight,
    Function(int) getValue,
    Color color,
    String label,
  ) {
    final path = Path();
    final areaPath = Path();
    final points = <Offset>[];

    // Generate points
    for (int day = 1; day <= cycleLength; day++) {
      final x = startX + (day / cycleLength) * graphWidth;
      final value = getValue(day);
      final y = startY + graphHeight - (value * graphHeight);
      points.add(Offset(x, y));
    }

    // Draw area under curve with gradient
    areaPath.moveTo(points.first.dx, startY + graphHeight);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      areaPath.quadraticBezierTo(
        (p1.dx + p2.dx) / 2,
        (p1.dy + p2.dy) / 2,
        p2.dx,
        p2.dy,
      );
    }
    areaPath.lineTo(points.last.dx, startY + graphHeight);
    areaPath.close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.05),
          ],
        ).createShader(areaPath.getBounds()),
    );

    // Draw curve line
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      path.quadraticBezierTo(
        (p1.dx + p2.dx) / 2,
        (p1.dy + p2.dy) / 2,
        p2.dx,
        p2.dy,
      );
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Draw dots on curve
    for (final point in points) {
      canvas.drawCircle(
        point,
        2,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  // Estrogen pattern: low in menstrual, rises in follicular, peaks at ovulation, drops in luteal
  double _getEstrogen(int day) {
    if (day >= 1 && day <= 5) return 0.2; // Menstrual: low
    if (day >= 6 && day <= 12) return 0.2 + (day - 6) * 0.1; // Follicular: rising
    if (day >= 13 && day <= 15) return 0.8; // Ovulation: peak
    if (day >= 16 && day <= 28) return 0.8 - (day - 15) * 0.025; // Luteal: declining
    return 0.2;
  }

  // Progesterone pattern: low until ovulation, then rises in luteal
  double _getProgesterone(int day) {
    if (day >= 1 && day <= 14) return 0.1; // Low until ovulation
    if (day >= 15 && day <= 21) return 0.1 + (day - 14) * 0.08; // Rising in luteal
    if (day >= 22 && day <= 28) return 0.7 - (day - 21) * 0.1; // Declining
    return 0.1;
  }

  @override
  bool shouldRepaint(HormonalCurvePainter oldDelegate) {
    return oldDelegate.currentDay != currentDay;
  }
}
