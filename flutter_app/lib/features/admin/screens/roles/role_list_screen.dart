import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/widgets/async_value_widget.dart';
import 'package:flutter_app/features/admin/models/role_model.dart';
import 'package:flutter_app/features/admin/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/widgets/app_bar_actions.dart';

const _allPermissions = [
  'user:create',
  'user:read',
  'user:update',
  'user:delete',
  'role:create',
  'role:read',
  'role:update',
  'role:delete',
  'service:create',
  'service:read',
  'service:update',
  'service:delete',
  'forest:create',
  'forest:read',
  'forest:update',
  'forest:delete',
  'parcelle:create',
  'parcelle:read',
  'parcelle:update',
  'parcelle:delete',
  'assignment:create',
  'assignment:read',
  'assignment:delete',
  'incident:create',
  'incident:read',
  'incident:update',
  'incident:validate',
  'analytics:read',
];

const _resourceColors = {
  'user': AppColors.info,
  'role': AppColors.teal,
  'service': AppColors.sage,
  'forest': AppColors.primaryGreen,
  'parcelle': AppColors.darkForest,
  'assignment': AppColors.warning,
  'incident': AppColors.danger,
  'score': AppColors.info,
  'analytics': AppColors.teal,
  'notification': AppColors.warning,
};

class RoleListScreen extends ConsumerWidget {
  const RoleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesProvider);
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.rolesAndPermissions),
        actions: kAppBarActions,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.shield_outlined),
        label: Text(l.newRole),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => const _RoleFormDialog(),
          );
          ref.invalidate(rolesProvider);
        },
      ),
      body: AsyncValueWidget(
        value: rolesAsync,
        builder: (roles) => roles.isEmpty
            ? _EmptyState(
                onAdd: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => const _RoleFormDialog(),
                  );
                  ref.invalidate(rolesProvider);
                },
              )
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: roles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _RoleCard(
                  role: roles[i],
                  onRefresh: () => ref.invalidate(rolesProvider),
                ),
              ),
      ),
    );
  }
}

class _RoleCard extends ConsumerWidget {
  final RoleModel role;
  final VoidCallback onRefresh;
  const _RoleCard({required this.role, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final groups = <String, List<String>>{};
    for (final p in role.permissions) {
      final res = p.split(':')[0];
      groups.putIfAbsent(res, () => []).add(p.split(':')[1]);
    }

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: AppColors.primaryGreen,
            size: 20,
          ),
        ),
        title: Text(role.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          '${role.permissions.length} permission${role.permissions.length > 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: l.edit,
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => _RoleFormDialog(role: role),
                );
                onRefresh();
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.danger,
              ),
              tooltip: l.delete,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: Text(l.deleteRole),
                    content: Text('${l.delete} "${role.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: Text(l.cancel),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        ),
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: Text(l.delete),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(roleRepositoryProvider).deleteRole(role.id);
                  onRefresh();
                }
              },
            ),
          ],
        ),
        children: [
          if (groups.isEmpty)
            Text(
              l.noPermissionsAssigned,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: groups.entries.expand((entry) {
                final color =
                    _resourceColors[entry.key] ?? AppColors.primaryGreen;
                return entry.value.map(
                  (action) => _PermChip(
                    resource: entry.key,
                    action: action,
                    color: color,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _PermChip extends StatelessWidget {
  final String resource;
  final String action;
  final Color color;
  const _PermChip({
    required this.resource,
    required this.action,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            resource,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ':$action',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role form dialog ──────────────────────────────────────────────────────────

class _RoleFormDialog extends ConsumerStatefulWidget {
  final RoleModel? role;
  const _RoleFormDialog({this.role});

  @override
  ConsumerState<_RoleFormDialog> createState() => _RoleFormState();
}

class _RoleFormState extends ConsumerState<_RoleFormDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late Set<String> _selected;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.role?.name ?? '';
    _descCtrl.text = widget.role?.description ?? '';
    _selected = Set.from(widget.role?.permissions ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final groups = <String, List<String>>{};
    for (final p in _allPermissions) {
      final parts = p.split(':');
      groups.putIfAbsent(parts[0], () => []).add(parts[1]);
    }

    return AlertDialog(
      title: Text(widget.role == null ? l.newRole : l.editRole),
      content: SizedBox(
        width: 560,
        height: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l.roleNameLabel,
                  prefixIcon: const Icon(Icons.shield_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: l.description,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    l.permissions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        setState(() => _selected = Set.from(_allPermissions)),
                    child: Text(l.selectAll),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    onPressed: () => setState(() => _selected.clear()),
                    child: Text(l.clear),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selected.length} / ${_allPermissions.length} ${l.selected}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...groups.entries.map(
                (entry) => _PermGroup(
                  resource: entry.key,
                  actions: entry.value,
                  selected: _selected,
                  color: _resourceColors[entry.key] ?? AppColors.primaryGreen,
                  onToggle: (perm, on) => setState(
                    () => on ? _selected.add(perm) : _selected.remove(perm),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.role == null ? l.create : l.save),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.nameRequired)));
      return;
    }
    setState(() => _loading = true);
    try {
      final body = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'permissions': _selected.toList(),
      };
      final repo = ref.read(roleRepositoryProvider);
      widget.role == null
          ? await repo.createRole(body)
          : await repo.updateRole(widget.role!.id, body);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.errorPrefix} $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _PermGroup extends StatelessWidget {
  final String resource;
  final List<String> actions;
  final Set<String> selected;
  final Color color;
  final void Function(String perm, bool on) onToggle;

  const _PermGroup({
    required this.resource,
    required this.actions,
    required this.selected,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final allSelected = actions.every((a) => selected.contains('$resource:$a'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                resource.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  for (final a in actions) {
                    onToggle('$resource:$a', !allSelected);
                  }
                },
                child: Text(
                  allSelected ? l.clear : l.selectAll,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: actions.map((action) {
              final perm = '$resource:$action';
              final isOn = selected.contains(perm);
              return FilterChip(
                label: Text(action),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: isOn ? Colors.white : null,
                ),
                selected: isOn,
                selectedColor: color,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isOn ? color : color.withValues(alpha: 0.3),
                ),
                onSelected: (v) => onToggle(perm, v),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 64,
            color: AppColors.primaryGreen.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            l.noRolesDefined,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l.noRolesHint,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.shield_outlined),
            label: Text(l.newRole),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
