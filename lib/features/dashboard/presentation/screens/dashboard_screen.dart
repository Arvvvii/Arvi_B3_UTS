import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maauts003/core/theme/glassmorphism.dart';
import 'package:maauts003/features/auth/presentation/providers/auth_provider.dart';
import 'package:maauts003/features/auth/domain/user_model.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // refresh mock data
            await Future.delayed(const Duration(seconds: 1));
          },
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello,',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        authState.value?.name ?? 'User',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    radius: 24,
                    child: Icon(LucideIcons.user, color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Bento Grid Layout
              Row(
                children: [
                  Expanded(
                    child: _BentoCard(
                      title: 'Total Tickets',
                      value: '142',
                      icon: LucideIcons.layers,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BentoCard(
                      title: 'Resolved',
                      value: '89',
                      icon: LucideIcons.checkCircle,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _BentoCard(
                      title: 'In Progress',
                      value: '45',
                      icon: LucideIcons.loader,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BentoCard(
                      title: 'Open',
                      value: '8',
                      icon: LucideIcons.alertCircle,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              if (authState.value?.role == UserRole.user)
                ElevatedButton.icon(
                  onPressed: () => context.push('/tickets/create'),
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Create New Ticket'),
                ),

              const SizedBox(height: 32),
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GlassmorphismCard(
                padding: const EdgeInsets.all(0),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.fileText, color: Theme.of(context).primaryColor, size: 20),
                      ),
                      title: Text('Ticket #${1000 + index}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Status updated to In Progress'),
                      trailing: const Text('2h ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _BentoCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
