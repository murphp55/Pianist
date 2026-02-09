import 'package:flutter/material.dart';

class MetronomeIndicator extends StatelessWidget {
  const MetronomeIndicator({
    super.key,
    required this.currentBeat,
    required this.isActive,
  });

  final int currentBeat;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isHighlighted = isActive && index == currentBeat;
        final isDownbeat = index == 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isDownbeat ? 20 : 16,
          height: isDownbeat ? 20 : 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHighlighted
                ? (isDownbeat
                    ? const Color(0xFFDE6B35) // Orange for downbeat
                    : const Color(0xFF1F6E54)) // Green for other beats
                : const Color(0xFFE0D6C5),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: (isDownbeat
                              ? const Color(0xFFDE6B35)
                              : const Color(0xFF1F6E54))
                          .withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
