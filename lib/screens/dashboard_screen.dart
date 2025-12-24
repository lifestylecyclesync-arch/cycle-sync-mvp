import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../widgets/gradient_wrapper.dart';
import '../utils/cycle_utils.dart';
import '../models/phase.dart';
import '../utils/goal_manager.dart';
import '../utils/avatar_manager.dart';
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
  bool _expandedGoals = false; // Track if goals are expanded
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
    final goals = await GoalManager.getAllGoals();
    setState(() {
      _goals = goals;
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getPhaseColor(_getCurrentPhase()).withValues(alpha: 0.3),
                      _getPhaseColor(_getCurrentPhase()).withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Cycle Insights',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Color(0xFF333333),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Cycle day ${_getCurrentCycleDay()} of $_cycleLength',
                                  style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfileScreen()),
                              );
                              // Reload goals when returning from profile screen
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
                                    radius: 24,
                                    backgroundImage: FileImage(File(avatar!.photoPath!)),
                                  );
                                }
                                
                                return CircleAvatar(
                                  radius: 24,
                                  backgroundColor: avatar?.color ?? pastelColor,
                                  child: Text(
                                    avatar?.emoji ?? initials,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 60.0),
                child: Column(
                  children: [
                    // Skip Recovery Banner (dismissible)
                    if (!_skipRecoveryDismissed && _getCurrentPhase() == 'Menstrual')
                      _buildSkipRecoveryBanner(),

                    // Phase Banner
                    _buildPhaseBanner(),
                    const SizedBox(height: 24),

                    // Daily Recommendations
                    _buildDailyRecommendationsCard(),
                    const SizedBox(height: 24),

                    // Goals Section (moved from Profile, now prominent)
                    _buildGoalsCard(),
                    const SizedBox(height: 24),

                    // Phase Progress Circle
                    _buildPhaseProgressCard(),
                    const SizedBox(height: 24),

                    // Phase Details
                    _buildPhaseDetailsCard(),
                    const SizedBox(height: 24),

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

  // New Widget: Skip Recovery Banner
  Widget _buildSkipRecoveryBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade100,
            Colors.red.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Text('🛌', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prioritize Recovery',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'re in your menstrual phase. Get extra rest and hydration.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _dismissSkipRecoveryBanner,
            child: Icon(
              Icons.close,
              color: Colors.red.shade600,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // New Widget: Phase Banner
  Widget _buildPhaseBanner() {
    Phase? phase = CyclePhases.findPhaseByName(_getCurrentPhase());
    int currentDay = _getCurrentCycleDay();

    if (phase == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Navigate to Daily Detail screen for today
        _showTodayDetail();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getPhaseColor(_getCurrentPhase()).withValues(alpha: 0.2),
              _getPhaseColor(_getCurrentPhase()).withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getPhaseColor(_getCurrentPhase()).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getPhaseColor(_getCurrentPhase()).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                phase.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCurrentPhase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day $currentDay • ${phase.description}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward,
              color: _getPhaseColor(_getCurrentPhase()),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // New Widget: Daily Recommendations
  Widget _buildDailyRecommendationsCard() {
    Phase? phase = CyclePhases.findPhaseByName(_getCurrentPhase());

    if (phase == null) return const SizedBox.shrink();

    final recommendations = [
      {
        'emoji': '🍎',
        'title': 'Nutrition',
        'value': phase.dietName,
        'color': Colors.green,
      },
      {
        'emoji': '🏋️',
        'title': 'Fitness',
        'value': phase.workoutName,
        'color': Colors.blue,
      },
      {
        'emoji': '😊',
        'title': 'Mood',
        'value': phase.description,
        'color': Colors.purple,
      },
    ];

    return GestureDetector(
      onTap: _showTodayDetail,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Recommendations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: recommendations
                  .asMap()
                  .entries
                  .map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> rec = entry.value;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < recommendations.length - 1 ? 12 : 0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (rec['color'] as Color).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (rec['color'] as Color).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              rec['emoji'] as String,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec['title'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: (rec['color'] as Color),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    rec['value'] as String,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
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
    Phase? phase = CyclePhases.findPhaseByName(_getCurrentPhase());

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getPhaseColor(_getCurrentPhase()),
            _getPhaseColor(_getCurrentPhase()).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCurrentPhase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (phase != null)
                      Text(
                        phase.getDayRange(_cycleLength),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                phase?.emoji ?? '🌙',
                style: const TextStyle(fontSize: 50),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day $currentDay',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                '${(_cycleLength - currentDay)} days left',
                style: const TextStyle(
                  fontSize: 14,
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
    Phase? phase = CyclePhases.findPhaseByName(_getCurrentPhase());

    if (phase == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Phase Details',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('🍎', 'Diet Type', phase.dietName),
          const SizedBox(height: 8),
          _buildDetailRow('🏋️', 'Workout Type', phase.workoutName),
          const SizedBox(height: 8),
          _buildDetailRow('⏱️', 'Fasting Type', phase.fastingType),
          const SizedBox(height: 12),
          Text(
            'Energy Level',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            phase.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF333333),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
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
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hormonal Evolution',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          // Hormonal curve graph
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: HormonalCurvePainter(
                cycleLength: _cycleLength,
                currentDay: currentDay,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 12),
          // Phase labels
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        Text(
          days,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsCard() {
    return GestureDetector(
      onTap: _goals.isEmpty
          ? () async {
              // Empty state: open add goal dialog
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(openGoalDialog: true),
                ),
              );
              await _loadGoals();
            }
          : () async {
              // Full module list view
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(openGoalDialog: false),
                ),
              );
              await _loadGoals();
            },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎯 Your Goals',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                if (_goals.isNotEmpty)
                  Text(
                    '${_goals.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_goals.isEmpty)
              const Text(
                'Tap to set your wellness goals',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal badges (limited to 3 or all if expanded)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._goals
                          .take(_expandedGoals ? _goals.length : 3)
                          .map((goal) {
                        return _buildGoalBadge(goal);
                      }).toList(),
                      // Add + button
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade400, width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 14, color: Color(0xFF2D5016)),
                              SizedBox(width: 4),
                              Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D5016),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Show "+X more" if collapsed and goals overflow
                      if (!_expandedGoals && _goals.length > 3)
                        GestureDetector(
                          onTap: () {
                            setState(() => _expandedGoals = true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+${_goals.length - 3}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_expandedGoals && _goals.length > 3)
                        GestureDetector(
                          onTap: () {
                            setState(() => _expandedGoals = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400, width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Show less',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Summary metric
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_goals.length} goal${_goals.length != 1 ? 's' : ''} active',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666),
                          ),
                        ),
                        _buildGoalsCompletionIndicator(),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalBadge(Goal goal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _showGoalDetailsDialog(goal);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  if (goal.amount.isNotEmpty)
                    Text(
                      goal.amount,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF666666),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Edit button
          GestureDetector(
            onTap: () {
              _showEditGoalDialog(goal);
            },
            child: const Icon(
              Icons.edit,
              size: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(width: 6),
          // Delete button
          GestureDetector(
            onTap: () {
              _showDeleteConfirmation(goal);
            },
            child: const Icon(
              Icons.close,
              size: 14,
              color: Color(0xFFCC0000),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalDetailsDialog(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${goal.type}'),
            if (goal.frequency.isNotEmpty) Text('Frequency: ${goal.frequency}'),
            if (goal.amount.isNotEmpty) Text('Amount: ${goal.amount}'),
            if (goal.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Description: ${goal.description}'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditGoalDialog(goal);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(Goal goal) {
    late TextEditingController nameController;
    late TextEditingController amountController;
    late TextEditingController descriptionController;
    
    nameController = TextEditingController(text: goal.name);
    amountController = TextEditingController(text: goal.amount);
    descriptionController = TextEditingController(text: goal.description);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Goal Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount/Frequency'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              nameController.dispose();
              amountController.dispose();
              descriptionController.dispose();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Create updated goal with new values
              final updatedGoal = Goal(
                id: goal.id,
                name: nameController.text.isNotEmpty ? nameController.text : goal.name,
                type: goal.type,
                frequency: goal.frequency,
                frequencyValue: goal.frequencyValue,
                amount: amountController.text.isNotEmpty ? amountController.text : goal.amount,
                description: descriptionController.text,
                completedDates: goal.completedDates,
              );
              await GoalManager.updateGoal(updatedGoal);
              nameController.dispose();
              amountController.dispose();
              descriptionController.dispose();
              await _loadGoals();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Goal updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to delete "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await GoalManager.deleteGoal(goal.id);
              await _loadGoals();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCompletionIndicator() {
    if (_goals.isEmpty) {
      return const SizedBox.shrink();
    }

    // Simple indicator: show emoji based on completion level
    // For now, just show a simple message
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 14,
          color: Color(0xFF999999),
        ),
        SizedBox(width: 4),
        Text(
          'In progress',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}

// Custom painter for hormonal evolution curve
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
