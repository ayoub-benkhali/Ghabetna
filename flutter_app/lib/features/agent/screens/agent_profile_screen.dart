import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
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
    final l = context.l10n;
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.myProfile),
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
              ProfileHeader(
                user: user,
                onEditName: () =>
                    _showEditNameDialog(context, ref, user.fullName),
              ),
              const SizedBox(height: 20),

              // ── Score card ───────────────────────────────────────────
              const _ScorePlaceholderCard(),
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
                          l.accountInfo,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Divider(height: 20),
                        ProfileInfoTile(
                          icon: Icons.badge_outlined,
                          label: l.identifier,
                          value: '#${user.id}',
                        ),
                        ProfileInfoTile(
                          icon: Icons.email_outlined,
                          label: l.emailAddress,
                          value: user.email,
                        ),
                        ProfileInfoTile(
                          icon: Icons.verified_outlined,
                          label: l.status,
                          value: user.isActive ? l.active : l.inactive,
                          iconColor: user.isActive
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        ProfileInfoTile(
                          icon: Icons.calendar_month_outlined,
                          label: l.memberSince,
                          value: DateFormat(
                            'dd MMMM yyyy',
                            l.localeName,
                          ).format(user.createdAt),
                        ),
                        if (user.cin != null)
                          ProfileInfoTile(
                            icon: Icons.credit_card_outlined,
                            label: l.cin,
                            value: user.cin!,
                          ),
                        if (user.phoneNumber != null)
                          ProfileInfoTile(
                            icon: Icons.phone_outlined,
                            label: l.phone,
                            value: user.phoneNumber!,
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              tooltip: l.editPhone,
                              onPressed: () => _showEditPhoneDialog(
                                context,
                                ref,
                                user.phoneNumber!,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Incident stats ───────────────────────────────────────
              const _AgentIncidentStats(),
              const SizedBox(height: 12),

              // ── Parcelle assignment ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: user.parcelleId != null
                      ? ListTile(
                          leading: const Icon(
                            Icons.crop_square_outlined,
                            color: AppColors.primaryGreen,
                          ),
                          title: Text(l.assignedParcelle),
                          subtitle: Text('${l.parcelles} #${user.parcelleId}'),
                        )
                      : ListTile(
                          leading: const Icon(
                            Icons.crop_square_outlined,
                            color: Colors.grey,
                          ),
                          title: Text(l.noParcelleAssigned),
                          subtitle: Text(
                            l.contactSupervisor,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
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
                  label: Text(l.disconnect),
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

void _showEditPhoneDialog(
  BuildContext context,
  WidgetRef ref,
  String currentPhone,
) {
  final l = context.l10n;
  final ctrl = TextEditingController(text: currentPhone);
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.editPhone),
      content: TextField(
        controller: ctrl,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: l.phoneOptional,
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () async {
            final phone = ctrl.text.trim();
            if (phone.isNotEmpty) {
              await ref.read(profileUpdateProvider.notifier).updatePhone(phone);
            }
            if (context.mounted) Navigator.pop(dialogContext);
          },
          child: Text(l.save),
        ),
      ],
    ),
  );
}

// ── Score placeholder ─────────────────────────────────────────────────────────

class _ScorePlaceholderCard extends StatelessWidget {
  const _ScorePlaceholderCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
                    l.reliabilityScore,
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
                        l.scoreComingSoon,
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
  const _AgentIncidentStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
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
                l.myReports,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              incidentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(
                  '${l.errorPrefix} $e',
                  style: const TextStyle(fontSize: 12),
                ),
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
                        label: l.total,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        value: pending,
                        label: l.pending,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        value: inProgress,
                        label: l.inProgress,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        value: resolved,
                        label: l.resolved,
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
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.editNameTitle),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: l.fullNameRequired,
          prefixIcon: const Icon(Icons.person_outline),
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isNotEmpty) await onSave(name);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}
