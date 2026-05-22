import 'package:flutter/material.dart';

/// Smoothly lerps between numeric values without animating layout.
///
/// When [value] is `null` it just renders [placeholder] (default `--`).
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 420),
    this.curve = Curves.easeOutQuart,
    this.format,
    this.placeholder = '--',
  });

  final double? value;
  final TextStyle style;
  final Duration duration;
  final Curve curve;
  final String Function(double)? format;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    if (value == null) return Text(placeholder, style: style);
    final fmt = format ?? (v) => v.toStringAsFixed(0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value!),
      duration: duration,
      curve: curve,
      builder: (_, v, _) => Text(fmt(v), style: style),
    );
  }
}
