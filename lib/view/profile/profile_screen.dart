import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../core/colors.dart';
import '../../core/router/routes.dart';
import '../auth/auth_controller.dart';
import '../widgets/section_title.dart';
import '../widgets/will_inkwell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = Get.find<AuthController>();
    return Obx(() {
      final user = auth.user.value;
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          const SectionTitle('Profile'),
          const SizedBox(height: 12),
          if (user != null) ...[
            _IdentityCard(name: user.name, email: user.email, isGuest: user.isGuest),
            const SizedBox(height: 28),
          ],
          const _RowDivider(label: 'Account'),
          _SettingRow(
            icon: CupertinoIcons.bluetooth,
            label: 'Wearable',
            value: 'Mock band',
            onTap: () {},
          ),
          _SettingRow(
            icon: CupertinoIcons.bell,
            label: 'Reminders',
            value: 'On',
            onTap: () {},
          ),
          const SizedBox(height: 28),
          const _RowDivider(label: 'App'),
          _SettingRow(
            icon: CupertinoIcons.info_circle,
            label: 'About',
            onTap: () {},
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: WillInkwell(
              onTap: () async {
                await auth.signOut();
                if (context.mounted) context.go(WillRoutes.welcome);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WillColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sign out',
                  style: TextStyle(
                    color: WillColors.danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.isGuest,
  });

  final String name;
  final String? email;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WillColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: WillColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isGuest ? 'Guest account' : (email ?? 'Signed in'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: WillColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: WillColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WillInkwell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: WillColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: WillColors.textPrimary,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 13,
                  color: WillColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: WillColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
