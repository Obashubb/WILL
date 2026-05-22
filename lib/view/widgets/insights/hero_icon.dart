import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HeroIcon extends StatelessWidget {
  const HeroIcon({
    super.key,
    required this.color,
    required this.icon,
    required this.pulse,
  });

  final Color color;
  final IconData icon;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: color),
    );
    if (!pulse) return box;
    return box
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.06, 1.06),
          duration: 900.ms,
          curve: Curves.easeOutQuart,
        );
  }
}
