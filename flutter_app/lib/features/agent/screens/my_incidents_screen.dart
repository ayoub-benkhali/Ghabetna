import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/features/incidents/models/incident_model.dart';
import 'package:flutter_app/features/incidents/providers/incident_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MyIncidentsScreen extends ConsumerWidget {
  const MyIncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final incidents = ref.watch(myIncidentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.myReports),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myIncidentsProvider),
          ),
        ],
      ),
      body: incidents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l.errorPrefix} $e')),
        data: (list) => list.isEmpty
            ? Center(
                child: Text(
                  l.noIncidents,
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myIncidentsProvider),
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => _IncidentCard(incident: list[i]),
                ),
              ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final IncidentModel incident;
  const _IncidentCard({required this.incident});

  Color _statusColor(String status) => switch (status) {
    'pending' => Colors.orange,
    'in_progress' => Colors.blue,
    'resolved' => Colors.green,
    'rejected' => Colors.red,
    _ => Colors.grey,
  };

  String _localizeCategory(String raw, l) => switch (raw) {
    'feu' => l.typeIncendie,
    'coupe_illegale' => l.typeCoupeIllegale,
    'refuge_suspect' => l.typeRefugeSuspect,
    'trafic' => l.typeTrafic,
    'dechet' => l.typeDechet,
    'maladie' => l.typeMaladie,
    'autre' => l.typeAutre,
    _ => raw,
  };

  String _localizeStatus(String raw, l) => switch (raw) {
    'pending' => l.pending,
    'in_progress' => l.inProgress,
    'resolved' => l.resolved,
    'rejected' => l.rejected,
    _ => raw,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: incident.isCritical
            ? const Icon(Icons.warning, color: Colors.red)
            : const Icon(Icons.forest, color: Colors.green),
        title: Text(_localizeCategory(incident.category, l)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              incident.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              DateFormat('dd MMM yyyy – HH:mm').format(incident.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            _localizeStatus(incident.status, l),
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: _statusColor(
            incident.status,
          ).withValues(alpha: 0.15),
          side: BorderSide(color: _statusColor(incident.status), width: 0.5),
        ),
        isThreeLine: true,
      ),
    );
  }
}
