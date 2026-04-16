import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/incidents/models/incident_model.dart';
import 'package:flutter_app/features/supervisor/providers/supervisor_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

const _categoryLabels = {
  'feu': 'Incendie',
  'coupe_illegale': 'Coupe illégale',
  'refuge_suspect': 'Refuge suspect',
  'trafic': 'Trafic',
  'dechet': 'Déchets',
  'maladie': 'Maladie végétale',
  'autre': 'Autre',
};

class SupervisorIncidentScreen extends ConsumerWidget {
  const SupervisorIncidentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allIncidentsProvider);
    final filter = ref.watch(incidentFilterProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidents'),
        actions: [
          //view toggle: list and map
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Vue carte',
            onPressed: () => context.go('/supervisor/map'),
          ),
          _FilterButton(filter: filter),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 12),
              Text('Erreur:$e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(allIncidentsProvider),
                child: const Text('Réssayer'),
              ),
            ],
          ),
        ),
        data: (incidents) => incidents.isEmpty
            ? const Center(child: Text('Aucun incident signalé'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(allIncidentsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: incidents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _IncidentTile(incident: incidents[i]),
                ),
              ),
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  final IncidentModel incident;
  const _IncidentTile({required this.incident});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (incident.status) {
      'pending' => AppColors.warning,
      'in_progress' => AppColors.info,
      'resolved' => AppColors.success,
      'rejected' => AppColors.danger,
      _ => Colors.grey,
    };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: incident.isCritical
              ? AppColors.danger.withValues(alpha: .15)
              : AppColors.primaryGreen.withValues(alpha: .15),
          child: Icon(
            incident.isCritical ? Icons.warning_amber : Icons.forest,
            color: incident.isCritical
                ? AppColors.danger
                : AppColors.primaryGreen,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _categoryLabels[incident.category] ?? incident.category,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: .4)),
              ),
              child: Text(
                incident.status,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Agent:${incident.agentName ?? "-"}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              DateFormat('dd MMM yyyy à HH:mm').format(incident.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/supervisor/incidents/${incident.id}'),
      ),
    );
  }
}

//Simple filter bottome sheet button
class _FilterButton extends ConsumerWidget {
  final IncidentFilter filter;

  const _FilterButton({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = filter.status != null || filter.category != null;
    return IconButton(
      icon: Badge(
        isLabelVisible: isActive,
        child: const Icon(Icons.filter_list),
      ),
      onPressed: () => _showFilterSheet(context, ref, filter),
    );
  }

  void _showFilterSheet(
    BuildContext ctx,
    WidgetRef ref,
    IncidentFilter current,
  ) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => _FilterSheet(current: current, ref: ref),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  final IncidentFilter current;
  final WidgetRef ref;
  const _FilterSheet({required this.current, required this.ref});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  String? _status;
  String? _category;

  @override
  void initState() {
    super.initState();
    _status = widget.current.status;
    _category = widget.current.category;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Text('Statut', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['pending', 'in_progress', 'resolved', 'rejected'].map((
              s,
            ) {
              return FilterChip(
                label: Text(s),
                selected: _status == s,
                onSelected: (v) => setState(() => _status = v ? s : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Catégorie',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _categoryLabels.entries.map((e) {
              return FilterChip(
                label: Text(e.value),
                selected: _category == e.key,
                onSelected: (v) => setState(() => _category = v ? e.key : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  widget.ref.read(incidentFilterProvider.notifier).state =
                      const IncidentFilter();
                  Navigator.pop(context);
                },
                child: const Text('Réinitialiser'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.ref.read(incidentFilterProvider.notifier).state =
                        IncidentFilter(status: _status, category: _category);
                    Navigator.pop(context);
                  },
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
