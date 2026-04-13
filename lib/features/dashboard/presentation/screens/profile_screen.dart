import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:maauts003/core/theme/theme_provider.dart';
import 'package:maauts003/features/auth/presentation/providers/auth_provider.dart';
import 'package:maauts003/core/theme/glassmorphism.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Icon(LucideIcons.user, size: 50, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'User Name',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? 'email@example.com',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user?.role.toString().split('.').last.toUpperCase() ?? 'USER',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GlassmorphismCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: const Icon(LucideIcons.moon),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
            ),
            icon: const Icon(LucideIcons.logOut),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
