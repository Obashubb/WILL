import 'package:flutter/material.dart';

import '../../../core/colors.dart';

class YAxisSidebar extends StatelessWidget {
  const YAxisSidebar({
    super.key,
    required this.minY,
    required this.maxY,
    required this.interval,
    required this.format,
  });

  final double minY;
  final double maxY;
  final double interval;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    // bottomTitles inside the chart reserve 22 pt; subtract so labels
    // align with the plotted band, not the axis strip.
    const bottomAxisReserve = 22.0;
    const labelHeight = 14.0;

    final values = <double>[];
    final edgeGuard = interval * 0.4;
    for (var v = maxY; v >= minY - 0.001; v -= interval) {
      if ((v - minY).abs() < edgeGuard || (v - maxY).abs() < edgeGuard) {
        continue;
      }
      values.add(v);
    }

    return Container(
      decoration: BoxDecoration(
        color: WillColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plotHeight = constraints.maxHeight - bottomAxisReserve;
          return SizedBox(
            width: 32,
            child: Stack(
              children: [
                for (final v in values)
                  Positioned(
                    right: 0,
                    left: 0,
                    top: (1 - (v - minY) / (maxY - minY)) * plotHeight -
                        labelHeight / 2,
                    child: Text(
                      format(v),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10,
                        color: WillColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
