import 'package:flutter/material.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────

class _P {
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFF5F2EF);
  static const border      = Color(0xFFEDEAE5);
  static const ink         = Color(0xFF1A1714);
  static const inkMid      = Color(0xFF6B6360);
  static const accent      = Color(0xFFB85C50);
  static const accentSoft  = Color(0xFFF2E8E6);
}

// ─── FilterChipItem ───────────────────────────────────────────────────────────

class FilterChipItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterChipItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _P.ink : _P.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _P.ink : _P.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A1714).withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: .1,
            color: selected ? Colors.white : _P.inkMid,
          ),
        ),
      ),
    );
  }
}