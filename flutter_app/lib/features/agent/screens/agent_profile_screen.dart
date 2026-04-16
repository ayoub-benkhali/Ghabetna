import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/widgets/async_value_widget.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_app/features/incidents/providers/incident_provider.dart';
import 'package:flutter_app/features/shared/providers/profile_provider.dart';
import 'package:flutter_app/features/shared/widgets/profile_header.dart';
import 'package:flutter_app/features/shared/widgets/profile_info_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AgentProfileScreen extends ConsumerWidget {
  const AgentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(myProfileProvider),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: profileAsync,
        builder: (user) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(myProfileProvider),
          child: ListView(
            children: [
              // ── Header ──────────────────────────────────────────────
              ProfileHeader(user: user),
              const SizedBox(height: 20),

              // ── Score card (placeholder until scoring service) ──────
              _ScorePlaceholderCard(),
              const SizedBox(height: 12),

              // ── Account info ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations du compte',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Divider(height: 20),
                        ProfileInfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Identifiant',
                          value: '#${user.id}',
                        ),
                        ProfileInfoTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email,
                        ),
                        ProfileInfoTile(
                          icon: Icons.verified_outlined,
                          label: 'Statut',
                          value: user.isActive
                              ? 'Compte actif'
                              : 'Compte inactif',
                          iconColor: user.isActive
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        ProfileInfoTile(
                          icon: Icons.calendar_month_outlined,
                          label: 'Membre depuis',
                          value: DateFormat(
                            'dd MMMM yyyy',
                            'fr',
                          ).format(user.createdAt),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Incident stats ───────────────────────────────────────
              _AgentIncidentStats(),
              const SizedBox(height: 12),

              // ── Parcelle assignment ──────────────────────────────────
              if (user.parcelleId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.crop_square_outlined,
                        color: AppColors.primaryGreen,
                      ),
                      title: const Text('Parcelle assignée'),
                      subtitle: Text('Parcelle #${user.parcelleId}'),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.crop_square_outlined,
                        color: Colors.grey,
                      ),
                      title: const Text('Aucune parcelle assignée'),
                      subtitle: const Text(
                        'Contactez votre superviseur pour une affectation.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // ── Edit name ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier mon nom'),
                  onPressed: () =>
                      _showEditNameDialog(context, ref, user.fullName),
                ),
              ),
              const SizedBox(height: 12),

              // ── Logout ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('Se déconnecter'),
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (_) => _EditNameDialog(
        controller: ctrl,
        onSave: (name) =>
            ref.read(profileUpdateProvider.notifier).updateName(name),
      ),
    );
  }
}

// ── Score placeholder ─────────────────────────────────────────────────────────

class _ScorePlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_outline, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Score de fiabilité',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_top_outlined,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Disponible après le Sprint 4. Continuez à signaler des incidents !',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Agent incident stats ──────────────────────────────────────────────────────

class _AgentIncidentStats extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(myIncidentsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mes signalements',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              incidentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Erreur: $e', style: const TextStyle(fontSize: 12)),
                data: (incidents) {
                  final total = incidents.length;
                  final pending = incidents
                      .where((i) => i.status == 'pending')
                      .length;
                  final resolved = incidents
                      .where((i) => i.status == 'resolved')
                      .length;
                  final inProgress = incidents
                      .where((i) => i.status == 'in_progress')
                      .length;

                  return Row(
                    children: [
                      _StatChip(
                        value: total,
                        label: 'Total',
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        value: pending,
                        label: 'En attente',
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        value: inProgress,
                        label: 'En cours',
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        value: resolved,
                        label: 'Résolus',
                        color: AppColors.success,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared micro-widgets ──────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditNameDialog extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function(String) onSave;
  const _EditNameDialog({required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le nom'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Nom complet',
          prefixIcon: Icon(Icons.person_outline),
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              await onSave(name);
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
