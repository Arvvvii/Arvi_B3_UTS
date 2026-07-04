import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:arvi_b3_uts/features/auth/presentation/providers/auth_provider.dart';

/// [UPDATED v3.0.0] ProfileScreen sekarang HANYA menampilkan informasi user.
/// Semua pengaturan (Dark Mode, Logout, User Management) dipindahkan ke SettingScreen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Gear icon → navigasi ke Settings
          IconButton(
            icon: const Icon(LucideIcons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // === AVATAR ===
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  LucideIcons.user,
                  size: 56,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // === NAME ===
            Text(
              user?.name ?? 'User Name',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),

            // === EMAIL ===
            Text(
              user?.email ?? 'email@example.com',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),

            // === ROLE BADGE ===
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.role.toString().split('.').last.toUpperCase() ?? 'USER',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // === INFO CARDS ===
            _InfoCard(
              icon: LucideIcons.mail,
              label: 'Email',
              value: user?.email ?? '-',
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: LucideIcons.shield,
              label: 'Role',
              value: user?.role.toString().split('.').last ?? 'user',
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: LucideIcons.activity,
              label: 'Status',
              value: (user?.isActive ?? true) ? 'Active' : 'Inactive',
            ),
          ],
        ),
      ),
    );
  }
}

/// Card sederhana untuk menampilkan informasi detail user.
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.outline,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
