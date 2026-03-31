import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_app/features/admin/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forests = ref.watch(forestsProvider);
    final users = ref.watch(usersProvider);
    final services = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vue d\'ensemble',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Données du système en temps réel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _KpiCard(
                  icon: Icons.forest,
                  label: 'Forêts',
                  color: AppColors.primaryGreen, // was Colors.green
                  value: forests.when(
                    data: (d) => '${d.length}',
                    loading: () => '…',
                    error: (_, __) => '!',
                  ),
                ),
                _KpiCard(
                  icon: Icons.people,
                  label: 'Utilisateurs',
                  color: AppColors.info, // was Colors.blue
                  value: users.when(
                    data: (d) => '${d.length}',
                    loading: () => '…',
                    error: (_, __) => '!',
                  ),
                ),
                _KpiCard(
                  icon: Icons.account_tree,
                  label: 'Services',
                  color: AppColors.warning, // was Colors.orange
                  value: services.when(
                    data: (d) => '${d.length}',
                    loading: () => '…',
                    error: (_, __) => '!',
                  ),
                ),
                // REPLACE the Parcelles KpiCard:
                _KpiCard(
                  icon: Icons.map_outlined,
                  label: 'Parcelles',
                  color: AppColors.teal,
                  value: forests.when(
                    data: (list) =>
                        '${list.fold(0, (sum, f) => sum + f.parcelleCount)}',
                    loading: () => '…',
                    error: (_, __) => '!',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String value;
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      // Card styling (border-radius, color, elevation) comes from cardTheme in buildTheme()
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
