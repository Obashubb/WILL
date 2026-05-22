import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PulseDot extends StatelessWidget {
  const PulseDot({
    super.key,
    required this.color,
    required this.active,
    this.size = 10,
  });

  final Color color;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
          ),
        ],
      ),
    );

    if (!active) return dot;

    return SizedBox(
      width: size * 4,
      height: size * 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(2, (i) {
            return Container(
              width: size * 4,
              height: size * 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(),
                  delay: (i * 750).ms,
                )
                .scale(
                  begin: const Offset(0.25, 0.25),
                  end: const Offset(1, 1),
                  duration: 1500.ms,
                  curve: Curves.easeOutQuart,
                )
                .fadeOut(
                  duration: 1500.ms,
                  curve: Curves.easeOutQuart,
                );
          }),
          dot,
        ],
      ),
    );
  }
}
