import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Custom FAB Widget for Cycle Sync MVP
/// Provides quick access to:
/// - Log Symptoms & Notes
/// - Add Goal
class CycleFAB extends StatefulWidget {
  final VoidCallback onLogSymptoms;
  final VoidCallback onAddGoal;

  const CycleFAB({
    super.key,
    required this.onLogSymptoms,
    required this.onAddGoal,
  });

  @override
  State<CycleFAB> createState() => _CycleFABState();
}

class _CycleFABState extends State<CycleFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;
  bool _showTooltip = false;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenFABTooltip = prefs.getBool('hasSeenFABTooltip') ?? false;

    if (!hasSeenFABTooltip) {
      setState(() {
        _showTooltip = true;
      });

      // Auto-hide tooltip after 5 seconds
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _showTooltip = false;
        });
      }

      // Mark as seen
      await prefs.setBool('hasSeenFABTooltip', true);
    }
  }

  void _toggleFAB() {
    if (_showTooltip) {
      setState(() {
        _showTooltip = false;
      });
    }

    if (_isExpanded) {
      _controller.reverse();
    } else {
      _controller.forward();
    }

    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _handleLogSymptoms() {
    _toggleFAB(); // Close the FAB menu
    widget.onLogSymptoms();
  }

  void _handleAddGoal() {
    _toggleFAB(); // Close the FAB menu
    widget.onAddGoal();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Tooltip
        if (_showTooltip)
          Positioned(
            bottom: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '✨ Quick actions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

        // Scrim (background overlay when expanded)
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleFAB,
              child: Container(
                color: Colors.black.withValues(alpha: 0.0),
              ),
            ),
          ),

        // Log Symptoms FAB Item
        ScaleTransition(
          scale: _scaleAnimation,
          child: Positioned(
            bottom: 90,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'fab_symptoms',
              mini: true,
              backgroundColor: Colors.pink,
              onPressed: _handleLogSymptoms,
              tooltip: 'Log Symptoms & Notes',
              child: const Icon(Icons.note_add, color: Colors.white),
            ),
          ),
        ),

        // Add Goal FAB Item
        ScaleTransition(
          scale: _scaleAnimation,
          child: Positioned(
            bottom: 160,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'fab_goal',
              mini: true,
              backgroundColor: Colors.amber.shade600,
              onPressed: _handleAddGoal,
              tooltip: 'Add Goal',
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),

        // Main FAB with expansion animation
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label for expanded state
              if (_isExpanded)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              // Main FAB
              FloatingActionButton(
                heroTag: 'fab_main',
                onPressed: _toggleFAB,
                backgroundColor: Colors.purple,
                elevation: 4,
                child: RotationTransition(
                  turns: _rotateAnimation,
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
