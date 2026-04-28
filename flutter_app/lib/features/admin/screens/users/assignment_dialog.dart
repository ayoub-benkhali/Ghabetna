import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/admin/models/forest_model.dart';
import 'package:flutter_app/features/admin/models/user_model.dart';
import 'package:flutter_app/features/admin/providers/assignment_provider.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssignmentDialog extends ConsumerStatefulWidget {
  final UserModel user;
  const AssignmentDialog({super.key, required this.user});

  @override
  ConsumerState<AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends ConsumerState<AssignmentDialog> {
  bool _loading = false;
  String? _error;

  //supervisor state
  int? _selectedForestId;

  //Agent state
  int? _selectedForestFilterId;
  int? _selectedParcelleId;

  @override
  void initState() {
    super.initState();
    //pre-select current assignments
    if (widget.user.roleName == 'supervisor') {
      _selectedForestId = widget.user.forestId;
    } else if (widget.user.roleName == 'agent') {
      _selectedParcelleId = widget.user.parcelleId;
    }
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(assignmentRepositoryProvider);
    try {
      if (widget.user.roleName == 'supervisor') {
        if (_selectedForestId != null) {
          await repo.unassignSupervisor(widget.user.id);
          await repo.assignSupervisorToForest(
            widget.user.id,
            _selectedForestId!,
          );
        }
      } else if (widget.user.roleName == 'agent') {
        if (_selectedParcelleId == null) {
          await repo.unassignAgent(widget.user.id);
        } else {
          await repo.assignAgentToParcelle(
            widget.user.id,
            _selectedParcelleId!,
          );
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeAssignment() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(assignmentRepositoryProvider);
    try {
      if (widget.user.roleName == 'supervisor') {
        await repo.unassignSupervisor(widget.user.id);
        setState(() => _selectedForestId = null);
      } else {
        await repo.unassignAgent(widget.user.id);
        setState(() {
          _selectedParcelleId = null;
          _selectedForestFilterId = null;
        });
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isSupervisor = widget.user.roleName == 'supervisor';
    final hasCurrentAssignment = isSupervisor
        ? widget.user.forestId != null
        : widget.user.parcelleId != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.assessment_outlined,
            color: AppColors.primaryGreen,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.assignmentOf(widget.user.fullName),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoleChip(roleName: widget.user.roleName),
            const SizedBox(height: 16),

            if (hasCurrentAssignment)
              _CurrentAssignmentBanner(
                isSupervisor: isSupervisor,
                forestId: widget.user.forestId,
                parcelleId: widget.user.parcelleId,
              ),
            if (hasCurrentAssignment) const SizedBox(height: 16),

            if (isSupervisor)
              _ForestSelector(
                selectedForestId: _selectedForestId,
                onChanged: (v) => setState(() => _selectedForestId = v),
              )
            else
              _ParcelleSelector(
                selectedForestId: _selectedForestFilterId,
                selectedParcelleId: _selectedParcelleId,
                onForestChanged: (v) => setState(() {
                  _selectedForestFilterId = v;
                  _selectedParcelleId = null;
                }),
                onParcelleChanged: (v) =>
                    setState(() => _selectedParcelleId = v),
              ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        if (hasCurrentAssignment)
          TextButton.icon(
            icon: const Icon(Icons.link_off, size: 16, color: AppColors.danger),
            label: Text(
              l.cancel,
              style: const TextStyle(color: AppColors.danger),
            ),
            onPressed: _loading ? null : _removeAssignment,
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: Text(l.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l.save),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _RoleChip extends StatelessWidget {
  final String roleName;
  const _RoleChip({required this.roleName});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = roleName == 'supervisor'
        ? AppColors.warning
        : AppColors.primaryGreen;
    final label = roleName == 'supervisor'
        ? l.supervisorToForest
        : l.agentToParcelle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CurrentAssignmentBanner extends ConsumerWidget {
  final bool isSupervisor;
  final int? forestId;
  final int? parcelleId;

  const _CurrentAssignmentBanner({
    required this.isSupervisor,
    required this.forestId,
    required this.parcelleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final forests = ref.watch(forestsProvider);
    String label = '—';

    if (isSupervisor && forestId != null) {
      label = forests.maybeWhen(
        data: (list) => list
            .firstWhere(
              (f) => f.id == forestId,
              orElse: () => ForestModel(
                id: forestId!,
                name: '${l.forests} #$forestId',
                createdAt: DateTime.now(),
              ),
            )
            .name,
        orElse: () => '${l.forests} #$forestId',
      );
    } else if (!isSupervisor && parcelleId != null) {
      label = '${l.parcelles} #$parcelleId';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.info,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.currentAssignment(label),
              style: const TextStyle(fontSize: 13, color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}

// Supervisor: single forest dropdown

class _ForestSelector extends ConsumerWidget {
  final int? selectedForestId;
  final ValueChanged<int?> onChanged;

  const _ForestSelector({
    required this.selectedForestId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final forestsAsync = ref.watch(forestsProvider);
    return forestsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        '${l.errorPrefix} $e',
        style: const TextStyle(color: AppColors.danger),
      ),
      data: (forests) => DropdownButtonFormField<int?>(
        initialValue: selectedForestId,
        decoration: InputDecoration(
          labelText: l.assignedForest,
          prefixIcon: const Icon(Icons.forest_outlined),
        ),
        items: [
          DropdownMenuItem<int?>(value: null, child: Text(l.noNoneF)),
          ...forests.map(
            (f) => DropdownMenuItem<int?>(value: f.id, child: Text(f.name)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// Agent: forest filter → parcelle dropdown (two-step)

class _ParcelleSelector extends ConsumerWidget {
  final int? selectedForestId;
  final int? selectedParcelleId;
  final ValueChanged<int?> onForestChanged;
  final ValueChanged<int?> onParcelleChanged;

  const _ParcelleSelector({
    required this.selectedForestId,
    required this.selectedParcelleId,
    required this.onForestChanged,
    required this.onParcelleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final forestsAsync = ref.watch(forestsProvider);
    final parcellesAsync = selectedForestId != null
        ? ref.watch(parcellesProvider(selectedForestId!))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step 1: pick forest
        forestsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(
            '${l.errorPrefix} $e',
            style: const TextStyle(color: AppColors.danger),
          ),
          data: (forests) => DropdownButtonFormField<int?>(
            initialValue: selectedForestId,
            decoration: InputDecoration(
              labelText: l.chooseForest,
              prefixIcon: const Icon(Icons.forest_outlined),
            ),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text(l.selectOption)),
              ...forests.map(
                (f) => DropdownMenuItem<int?>(value: f.id, child: Text(f.name)),
              ),
            ],
            onChanged: onForestChanged,
          ),
        ),
        const SizedBox(height: 12),
        // Step 2: pick parcelle within that forest
        if (selectedForestId != null)
          parcellesAsync!.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              '${l.errorPrefix} $e',
              style: const TextStyle(color: AppColors.danger),
            ),
            data: (parcelles) => parcelles.isEmpty
                ? Text(
                    l.noParcellInForest,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  )
                : DropdownButtonFormField<int?>(
                    initialValue: selectedParcelleId,
                    decoration: InputDecoration(
                      labelText: l.chooseParcelle,
                      prefixIcon: const Icon(Icons.map_outlined),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l.noNoneF),
                      ),
                      ...parcelles.map(
                        (p) => DropdownMenuItem<int?>(
                          value: p.id,
                          child: Text(p.name),
                        ),
                      ),
                    ],
                    onChanged: onParcelleChanged,
                  ),
          )
        else
          DropdownButtonFormField<int?>(
            initialValue: null,
            decoration: InputDecoration(
              labelText: l.chooseParcelle,
              prefixIcon: const Icon(Icons.map_outlined),
              enabled: false,
            ),
            items: const [],
            onChanged: null,
            hint: Text(l.selectForestFirst),
          ),
      ],
    );
  }
}
