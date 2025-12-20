import 'package:flutter/material.dart';

class GradientWrapper extends StatelessWidget {
  final Widget child;

  const GradientWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFC0C0F9), // Lavender
              Color(0xFFF9C0C0), // Pastel Pink
              Color(0xFF97E7F9), // Soft Sky Blue
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}
