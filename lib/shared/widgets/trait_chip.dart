import 'package:flutter/material.dart';

import '../../core/theme/petpal_theme.dart';

class TraitChip extends StatelessWidget {
  const TraitChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected ? const Color(0xFFFBE2BC) : const Color(0xFFF7ECCA),
          foregroundColor: selected ? PetPalColors.honey : PetPalColors.cocoa,
          side: BorderSide(
            color: selected ? PetPalColors.honey : PetPalColors.line,
            width: 2,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        child: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
