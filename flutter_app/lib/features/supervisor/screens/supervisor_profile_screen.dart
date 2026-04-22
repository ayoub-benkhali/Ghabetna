import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/widgets/app_bar_actions.dart';
import 'package:flutter_app/core/widgets/async_value_widget.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_app/features/shared/providers/profile_provider.dart';
import 'package:flutter_app/features/shared/widgets/profile_header.dart';
import 'package:flutter_app/features/shared/widgets/profile_info_tile.dart';
import 'package:flutter_app/features/supervisor/providers/supervisor_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SupervisorProfileScreen extends ConsumerWidget {
  const SupervisorProfileScreen({super.key});

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
          ...kAppBarActions,
        ],
      ),
      body: AsyncValueWidget(
        value: profileAsync,
        builder: (user) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(myProfileProvider),
          child: ListView(
            children: [
              ProfileHeader(user: user),
              const SizedBox(height: 20),

              // ── Account details ──────────────────────────────────────
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

              // ── Incident overview ────────────────────────────────────
              const _SupervisorIncidentOverview(),
              const SizedBox(height: 12),

              // ── Assigned forest ──────────────────────────────────────
              if (user.forestId != null)
                _AssignedForestCard(forestId: user.forestId!)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.forest_outlined,
                        color: Colors.grey,
                      ),
                      title: Text(l.noForestAssigned),
                      subtitle: Text(
                        l.contactAdmin,
                        style: const TextStyle(fontSize: 12),
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
                  label: Text(l.editName),
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
    final l = context.l10n;
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.editNameTitle),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: l.fullNameRequired,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await ref.read(profileUpdateProvider.notifier).updateName(name);
              }
              if (context.mounted) Navigator.pop(dialogContext);
            },
            child: Text(l.save),
          ),
        ],
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

// ── Incident overview widget ──────────────────────────────────────────────────

class _SupervisorIncidentOverview extends ConsumerWidget {
  const _SupervisorIncidentOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final incidentsAsync = ref.watch(allIncidentsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart_outlined,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.incidentOverview,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
                  final critical = incidents.where((i) => i.isCritical).length;
                  final pending = incidents
                      .where((i) => i.status == 'pending')
                      .length;
                  final resolved = incidents
                      .where((i) => i.status == 'resolved')
                      .length;

                  return Column(
                    children: [
                      Row(
                        children: [
                          _StatBox(
                            value: total,
                            label: l.total,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          _StatBox(
                            value: critical,
                            label: l.critical,
                            color: AppColors.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatBox(
                            value: pending,
                            label: l.pending,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          _StatBox(
                            value: resolved,
                            label: l.resolved,
                            color: AppColors.success,
                          ),
                        ],
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

// ── Assigned forest card ──────────────────────────────────────────────────────

class _AssignedForestCard extends ConsumerWidget {
  final int forestId;
  const _AssignedForestCard({required this.forestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final forestsAsync = ref.watch(forestsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: forestsAsync.when(
        loading: () => Card(
          child: ListTile(
            leading: const CircularProgressIndicator(),
            title: Text(l.loading),
          ),
        ),
        error: (e, _) => Card(
          child: ListTile(
            leading: const Icon(Icons.error_outline, color: AppColors.danger),
            title: Text('${l.errorPrefix} $e'),
          ),
        ),
        data: (forests) {
          final forest = forests.where((f) => f.id == forestId).firstOrNull;
          if (forest == null) {
            return Card(
              child: ListTile(
                leading: const Icon(
                  Icons.forest_outlined,
                  color: AppColors.primaryGreen,
                ),
                title: Text('${l.forests} #$forestId'),
              ),
            );
          }
          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.forest_outlined,
                color: AppColors.primaryGreen,
              ),
              title: Text(forest.name),
              subtitle: Text(
                forest.region != null
                    ? '${l.region} : ${forest.region}'
                    : '${forest.parcelleCount} ${l.parcelles}',
              ),
              trailing: forest.areaHectares != null
                  ? Text(
                      '${forest.areaHectares!.toStringAsFixed(1)} ha',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

// ── Stat box ──────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                fontSize: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
