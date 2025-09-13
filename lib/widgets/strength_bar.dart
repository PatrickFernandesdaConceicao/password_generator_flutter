import 'package:flutter/material.dart';

class StrengthBar extends StatelessWidget {
  final double score;
  const StrengthBar({required this.score, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: score.clamp(0, 1),
        minHeight: 10,
      ),
    );
  }
}
