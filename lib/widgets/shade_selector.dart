import 'package:flutter/material.dart';
import '../models/shade.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────

class _P {
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFF5F2EF);
  static const border      = Color(0xFFEDEAE5);
  static const ink         = Color(0xFF1A1714);
  static const inkMid      = Color(0xFF6B6360);
  static const inkLight    = Color(0xFFB0AAA6);
  static const accent      = Color(0xFFB85C50);
  static const accentSoft  = Color(0xFFF2E8E6);
}

// ─── ShadeSelector ───────────────────────────────────────────────────────────

class ShadeSelector extends StatelessWidget {
  final List<Shade> shades;
  final Shade? selected;
  final void Function(Shade shade) onSelect;

  const ShadeSelector({
    super.key,
    required this.shades,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (shades.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header
        Row(
          children: [
            const Text(
              "CHOOSE SHADE",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: _P.inkMid,
              ),
            ),
            const Spacer(),
            if (selected != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _P.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selected!.name,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _P.accent,
                    letterSpacing: .1,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Shade rows
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: shades.map((s) {
            final isSelected = selected?.id == s.id;

            return GestureDetector(
              onTap: () => onSelect(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _P.accentSoft : _P.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _P.accent.withOpacity(0.5) : _P.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1A1714).withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shade dot
                    Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? _P.accentSoft : _P.surfaceWarm,
                        border: Border.all(
                          color: isSelected ? _P.accent : _P.border,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Shade name + tone/undertone
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.2,
                            color: isSelected ? _P.accent : _P.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${s.tone} · ${s.undertone}",
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _P.inkMid,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Selected indicator
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey("on"),
                              size: 18,
                              color: _P.accent,
                            )
                          : const Icon(
                              Icons.circle_outlined,
                              key: ValueKey("off"),
                              size: 18,
                              color: _P.inkLight,
                            ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}