import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:arvi_b3_uts/core/theme/theme_provider.dart';
import 'package:arvi_b3_uts/core/theme/glassmorphism.dart';
import 'package:arvi_b3_uts/features/auth/presentation/providers/auth_provider.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/providers/ticket_provider.dart';

/// SettingScreen berisi pengaturan aplikasi:
/// - Dark/Light mode toggle
/// - Logout action
/// - Informasi versi aplikasi
class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final user = ref.watch(authProvider).value;
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // === USER INFO CARD ===
          GlassmorphismCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
                  child: Icon(
                    LucideIcons.user,
                    size: 28,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'User',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user?.role.toString().split('.').last.toUpperCase() ?? 'USER',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (user?.role.toString().split('.').last.toLowerCase() == 'admin') ...[
            const SizedBox(height: 32),
            Text(
              'Admin Panel',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            GlassmorphismCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.users, color: Colors.red),
                ),
                title: const Text('User Management', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Aktif/non-aktifkan pengguna', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                trailing: const Icon(LucideIcons.chevronRight, color: Colors.grey),
                onTap: () {
                  context.push('/user-management');
                },
              ),
            ),
          ],

          const SizedBox(height: 32),

          // === APPEARANCE SECTION ===
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          GlassmorphismCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SwitchListTile(
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                isDark ? 'Tema gelap aktif' : 'Tema terang aktif',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.indigo.withOpacity(0.15)
                      : Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDark ? LucideIcons.moon : LucideIcons.sun,
                  color: isDark ? Colors.indigo : Colors.amber[700],
                ),
              ),
              value: isDark,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (val) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
          ),

          const SizedBox(height: 32),

          // === ABOUT SECTION ===
          Text(
            'About',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          GlassmorphismCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.info, color: Colors.blue),
                  ),
                  title: const Text('Version', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(
                    '2.0.0',
                    style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.server, color: Colors.green),
                  ),
                  title: const Text('Backend', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(
                    'Golang + Supabase',
                    style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // === LOGOUT BUTTON ===
          ElevatedButton.icon(
            onPressed: () async {
              // Tampilkan dialog konfirmasi
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await ref.read(authProvider.notifier).logout();
                
                // [v2.0.0] Invalidate state provider agar data user lama
                // tidak 'nyangkut' saat user baru login (menghindari dashboard tidak terupdate)
                ref.invalidate(ticketListProvider);
                ref.invalidate(dashboardStatsProvider);

                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(LucideIcons.logOut),
            label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
