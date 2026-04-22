import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/widgets/async_value_widget.dart';
import 'package:flutter_app/features/admin/models/user_model.dart';
import 'package:flutter_app/features/admin/providers/user_provider.dart';
import 'package:flutter_app/features/admin/screens/users/assignment_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/widgets/app_bar_actions.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.dashboard), actions: kAppBarActions),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_outlined),
        label: Text(l.newUser),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => const UserFormDialog(),
          );
          ref.invalidate(usersProvider);
        },
      ),
      body: AsyncValueWidget(
        value: usersAsync,
        builder: (users) => users.isEmpty
            ? _EmptyState(
                onAdd: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => const UserFormDialog(),
                  );
                  ref.invalidate(usersProvider);
                },
              )
            : _UserTable(
                users: users,
                onRefresh: () => ref.invalidate(usersProvider),
              ),
      ),
    );
  }
}

// ── Role badge color mapping ──────────────────────────────────────────────────

Color _roleColor(String roleName) {
  switch (roleName) {
    case 'admin':
      return AppColors.danger;
    case 'supervisor':
      return AppColors.warning;
    case 'agent':
      return AppColors.primaryGreen;
    default:
      return AppColors.info;
  }
}

IconData _roleIcon(String roleName) {
  switch (roleName) {
    case 'admin':
      return Icons.admin_panel_settings_outlined;
    case 'supervisor':
      return Icons.manage_accounts_outlined;
    case 'agent':
      return Icons.person_pin_outlined;
    default:
      return Icons.person_outline;
  }
}

// ── Table ─────────────────────────────────────────────────────────────────────

class _UserTable extends StatelessWidget {
  final List<UserModel> users;
  final VoidCallback onRefresh;
  const _UserTable({required this.users, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: constraints.maxWidth - 48,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Text(
                          '${users.length} ${l.users}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth - 48,
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        headingTextStyle: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 56,
                        columnSpacing: 24,
                        columns: [
                          DataColumn(label: Text(l.users.toUpperCase())),
                          DataColumn(label: Text(l.roles.toUpperCase())),
                          DataColumn(label: Text(l.services.toUpperCase())),
                          DataColumn(label: Text(l.status.toUpperCase())),
                          DataColumn(label: Text(l.actions.toUpperCase())),
                        ],
                        rows: users.map((u) => _buildRow(context, u)).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildRow(BuildContext context, UserModel u) {
    final l = context.l10n;
    final roleColor = _roleColor(u.roleName);
    final roleIcon = _roleIcon(u.roleName);

    return DataRow(
      cells: [
        // Name + email combined
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Text(
                  u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.fullName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(u.email, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
        // Role badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(roleIcon, color: roleColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  u.roleName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: roleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Service
        DataCell(
          u.serviceId != null
              ? Text(
                  'ID ${u.serviceId}',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : Text(
                  '—',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
        ),
        // Active status
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: u.isActive ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                u.isActive ? l.active : l.inactive,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: u.isActive ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Actions
        DataCell(
          Consumer(
            builder: (ctx, ref, _) {
              final lCtx = ctx.l10n;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: lCtx.edit,
                    onPressed: () async {
                      await showDialog(
                        context: ctx,
                        builder: (_) => UserFormDialog(user: u),
                      );
                      onRefresh();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      u.isActive
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                      color: u.isActive ? AppColors.danger : AppColors.success,
                    ),
                    tooltip: u.isActive ? lCtx.deactivate : lCtx.activate,
                    onPressed: () async {
                      await ref.read(userRepositoryProvider).updateUser(u.id, {
                        'is_active': !u.isActive,
                      });
                      onRefresh();
                    },
                  ),
                  if (u.roleName == 'agent' || u.roleName == 'supervisor')
                    IconButton(
                      icon: Icon(
                        Icons.assignment_outlined,
                        size: 18,
                        color:
                            (u.roleName == 'supervisor'
                                ? u.forestId != null
                                : u.parcelleId != null)
                            ? AppColors.primaryGreen
                            : Theme.of(ctx).hintColor,
                      ),
                      tooltip: lCtx.manageAssignment,
                      onPressed: () async {
                        final refreshNeeded = await showDialog<bool>(
                          context: ctx,
                          builder: (_) => AssignmentDialog(user: u),
                        );
                        if (refreshNeeded == true) onRefresh();
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Form dialog ───────────────────────────────────────────────────────────────

class UserFormDialog extends ConsumerStatefulWidget {
  final UserModel? user;
  const UserFormDialog({super.key, this.user});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  final _cin = TextEditingController();
  final _phoneNumber = TextEditingController();
  int? _roleId;
  int? _serviceId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _email.text = widget.user!.email;
      _fullName.text = widget.user!.fullName;
      _roleId = widget.user!.roleId;
      _serviceId = widget.user!.serviceId;
      _cin.text = widget.user?.cin ?? '';
      _phoneNumber.text = widget.user?.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _cin.dispose();
    _phoneNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rolesAsync = ref.watch(rolesProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final isEdit = widget.user != null;

    return AlertDialog(
      title: Text(isEdit ? l.editUser : l.newUser),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Email — only editable on create
              if (!isEdit)
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l.emailAddressRequired,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l.required;
                    if (!v.contains('@')) return l.emailInvalid;
                    return null;
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.user!.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fullName,
                decoration: InputDecoration(
                  labelText: l.fullNameRequired,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.isEmpty) ? l.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cin,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: l.cinOptional,
                  prefixIcon: const Icon(Icons.credit_card_outlined),
                  counterText: '',
                ),
                validator: (v) {
                  if (v != null &&
                      v.isNotEmpty &&
                      !RegExp(r'^\d{8}$').hasMatch(v)) {
                    return l.cinInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneNumber,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l.phoneOptional,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              // Role dropdown
              rolesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  '${l.errorPrefix} $e',
                  style: const TextStyle(color: AppColors.danger),
                ),
                data: (roles) => DropdownButtonFormField<int>(
                  initialValue: _roleId,
                  decoration: InputDecoration(
                    labelText: l.roleRequired,
                    prefixIcon: const Icon(Icons.shield_outlined),
                  ),
                  items: roles
                      .map(
                        (r) => DropdownMenuItem(
                          value: r.id,
                          child: Row(
                            children: [
                              Icon(
                                _roleIcon(r.name),
                                size: 16,
                                color: _roleColor(r.name),
                              ),
                              const SizedBox(width: 8),
                              Text(r.name),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _roleId = v),
                  validator: (v) => v == null ? l.required : null,
                ),
              ),
              const SizedBox(height: 12),
              // Service dropdown (optional)
              servicesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  '${l.errorPrefix} $e',
                  style: const TextStyle(color: AppColors.danger),
                ),
                data: (services) => DropdownButtonFormField<int?>(
                  initialValue: _serviceId,
                  decoration: InputDecoration(
                    labelText: l.serviceOptional,
                    prefixIcon: const Icon(Icons.account_tree_outlined),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        l.noNone,
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                    ...services.map(
                      (s) => DropdownMenuItem<int?>(
                        value: s.id,
                        child: Text(s.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _serviceId = v),
                ),
              ),
              // Activation info note (create only)
              if (!isEdit) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.activationEmailNote,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
              : Text(isEdit ? l.save : l.create),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      if (widget.user == null) {
        await repo.createUser({
          'email': _email.text.trim(),
          'full_name': _fullName.text.trim(),
          'cin': _cin.text.trim(),
          'phone_number': _phoneNumber.text.trim(),
          'role_id': _roleId,
          'service_id': _serviceId,
        });
      } else {
        await repo.updateUser(widget.user!.id, {
          'full_name': _fullName.text.trim(),
          'role_id': _roleId,
          'service_id': _serviceId,
        });
      }
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.primaryGreen.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            l.noUsersDefined,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l.noUsersHint,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.person_add_outlined),
            label: Text(l.createUser),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
