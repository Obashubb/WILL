import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../home/home_shell.dart';

class WillNavBar extends StatelessWidget {
  const WillNavBar({
    super.key,
    required this.currentTab,
    required this.onSelect,
  });

  final WillTab currentTab;
  final ValueChanged<WillTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: WillColors.background,
        border: Border(
          top: BorderSide(color: WillColors.textSecondary, width: 0.3),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            children: WillTab.values
                .map(
                  (tab) => Expanded(
                    child: _NavTab(
                      tab: tab,
                      isSelected: tab == currentTab,
                      onPressed: () => onSelect(tab),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.tab,
    required this.isSelected,
    required this.onPressed,
  });

  final WillTab tab;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? WillColors.primary : WillColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? WillColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: WillColors.primary.withValues(
                alpha: isSelected ? 0.25 : 0,
              ),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
