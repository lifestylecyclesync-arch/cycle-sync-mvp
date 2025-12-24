import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/goal_manager.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasSymptomData = false;
  bool _hasPreferences = false;
  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user has logged symptoms (in shared preferences)
      final symptomData = prefs.getString('userSymptoms');
      
      // Check if user has set preferences
      final hasPreferences = prefs.getString('nutrition') != null ||
          prefs.getString('fitness') != null ||
          prefs.getString('fasting') != null;
      
      // Load goals
      final goals = await GoalManager.getAllGoals();
      
      if (mounted) {
        setState(() {
          _hasSymptomData = symptomData != null && symptomData.isNotEmpty;
          _hasPreferences = hasPreferences;
          _goals = goals;
        });
      }
    } catch (e) {
      print('Error loading user data for insights: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.pink.shade400,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.pink.shade400,
          tabs: const [
            Tab(text: 'Trends'),
            Tab(text: 'Reports'),
            Tab(text: 'Nudges'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Trends Tab
          _buildTrendsTab(),
          // Reports Tab
          _buildReportsTab(),
          // Adaptive Nudges Tab
          _buildNudgesTab(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    if (!_hasSymptomData) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlaceholderCard(
              title: 'Trends',
              subtitle: 'Your cycle insights and patterns',
              icon: Icons.trending_up,
              message: 'Start logging symptoms to see your trends here.',
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'To see trends:',
              items: [
                'Log symptoms regularly in your daily logs',
                'Track how you feel across your cycle phases',
                'Monitor energy, mood, and physical changes',
              ],
              color: Colors.blue,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataCard(
            title: 'Cycle Patterns',
            content: 'Your symptoms and patterns are being tracked. Log more data to unlock detailed trend analysis.',
            icon: Icons.show_chart,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildDataCard(
            title: 'Phase Correlations',
            content: 'Based on your logs, we\'re finding connections between phases and how you feel.',
            icon: Icons.insights,
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          _buildDataCard(
            title: 'Symptom Timeline',
            content: 'Your symptoms and when they appear during your cycle are being analyzed.',
            icon: Icons.calendar_today,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    if (!_hasPreferences) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlaceholderCard(
              title: 'Reports',
              subtitle: 'Detailed cycle insights',
              icon: Icons.assessment,
              message: 'Complete your preferences to generate personalized reports.',
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'To see reports:',
              items: [
                'Set your lifestyle preferences (nutrition, fitness, fasting)',
                'Log how different activities affect your cycle',
                'Collect data across multiple cycles for patterns',
              ],
              color: Colors.green,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataCard(
            title: 'Nutrition Report',
            content: 'Your nutrition patterns are being tracked across your cycle phases.',
            icon: Icons.restaurant,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildDataCard(
            title: 'Fitness Report',
            content: 'See how your exercise patterns correlate with your energy levels.',
            icon: Icons.fitness_center,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildDataCard(
            title: 'Wellness Report',
            content: 'Overall wellness trends based on your logged preferences and goals.',
            icon: Icons.spa,
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildNudgesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlaceholderCard(
            title: 'Adaptive Nudges',
            subtitle: 'Personalized suggestions',
            icon: Icons.lightbulb,
            message: 'Get smart recommendations based on your cycle phase and goals.',
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Example nudges:',
            items: [
              '💪 "Great time for strength training today"',
              '💧 "Stay hydrated during your luteal phase"',
              '🧘 "Meditation might help with mood today"',
              '😴 "Prioritize sleep during your menstrual phase"',
            ],
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          // Sample nudge cards
          if (_goals.isEmpty)
            _buildSampleNudgeCard(
              title: 'Create Your First Goal',
              description:
                  'Start by adding a goal (hydration, fitness, nutrition, etc.) to get personalized nudges.',
              phase: 'All Phases',
              emoji: '🎯',
            )
          else ...[
            for (var i = 0; i < _goals.take(2).length; i++)
              Column(
                children: [
                  _buildSampleNudgeCard(
                    title: _getNudgeTitle(_goals[i].type),
                    description: _getNudgeDescription(_goals[i].type),
                    phase: 'Based on your phase',
                    emoji: _getNudgeEmoji(_goals[i].type),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: color.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.9),
                  ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: color.withOpacity(0.8),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleNudgeCard({
    required String title,
    required String description,
    required String phase,
    required String emoji,
  }) {
    return Card(
      elevation: 0,
      color: Colors.pink.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.pink.shade400,
                        ),
                      ),
                      Text(
                        phase,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNudgeTitle(String goalType) {
    switch (goalType.toLowerCase()) {
      case 'hydration':
      case 'water':
        return '💧 Stay Hydrated';
      case 'fitness':
      case 'exercise':
        return '💪 Strength Training';
      case 'nutrition':
        return '🥗 Balanced Nutrition';
      case 'sleep':
        return '😴 Prioritize Sleep';
      case 'meditation':
        return '🧘 Meditate Today';
      default:
        return '✨ Wellness Goal';
    }
  }

  String _getNudgeDescription(String goalType) {
    switch (goalType.toLowerCase()) {
      case 'hydration':
      case 'water':
        return 'Your hormones affect hydration needs. This is a perfect time to drink more water.';
      case 'fitness':
      case 'exercise':
        return 'Your energy levels are optimal right now – great time for high-intensity workouts.';
      case 'nutrition':
        return 'Your nutritional needs vary across your cycle. Consider foods rich in iron this phase.';
      case 'sleep':
        return 'Quality sleep is especially important during this phase for hormone balance.';
      case 'meditation':
        return 'A few minutes of mindfulness can help manage any mood changes this week.';
      default:
        return 'Keep tracking to unlock personalized suggestions for this phase.';
    }
  }

  String _getNudgeEmoji(String goalType) {
    switch (goalType.toLowerCase()) {
      case 'hydration':
      case 'water':
        return '💧';
      case 'fitness':
      case 'exercise':
        return '💪';
      case 'nutrition':
        return '🥗';
      case 'sleep':
        return '😴';
      case 'meditation':
        return '🧘';
      default:
        return '✨';
    }
  }
}

