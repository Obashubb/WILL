import 'package:flutter/material.dart';

class WillInkwell extends StatefulWidget {
  const WillInkwell({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 120),
    this.pressedOpacity = 0.6,
    this.curve = Curves.easeOut,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double pressedOpacity;
  final Curve curve;
  final HitTestBehavior behavior;

  @override
  State<WillInkwell> createState() => _WillInkwellState();
}

class _WillInkwellState extends State<WillInkwell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedOpacity(
        duration: widget.duration,
        curve: widget.curve,
        opacity: !enabled ? 0.4 : (_pressed ? widget.pressedOpacity : 1.0),
        child: widget.child,
      ),
    );
  }
}
