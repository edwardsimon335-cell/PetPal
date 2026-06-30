import 'package:flutter/material.dart';

class PetStatusBar extends StatelessWidget {
  const PetStatusBar({
    required this.value,
    required this.color,
    required this.icon,
    this.valueLabel,
    super.key,
  });

  final int value;
  final Color color;
  final IconData icon;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFAF0),
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: value.clamp(0, 100) / 100,
              backgroundColor: const Color(0xFFFFFAF0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 34,
          child: Text(
            valueLabel ?? '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFFFFFAF0),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
