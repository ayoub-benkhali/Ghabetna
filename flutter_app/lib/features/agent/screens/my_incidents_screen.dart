import 'package:flutter/material.dart';
import 'package:flutter_app/features/incidents/models/incident_model.dart';
import 'package:flutter_app/features/incidents/providers/incident_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const _categoryLabels = {
  'feu': 'Incendie',
  'coupe_illegale': 'Coupe illégale',
  'refuge_suspect': 'Refuge suspect',
  'trafic': 'Trafic',
  'dechet': 'Déchets',
  'maladie': 'Maladie',
  'autre': 'Autre',
};

class MyIncidentsScreen extends ConsumerWidget {
  const MyIncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(myIncidentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes signalements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myIncidentsProvider),
          ),
        ],
      ),
      body: incidents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (list) => list.isEmpty
            ? const Center(
                child: Text(
                  'Aucun signalement pour l\'instant',
                  style: TextStyle(color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: incident.isCritical
            ? const Icon(Icons.warning, color: Colors.red)
            : const Icon(Icons.forest, color: Colors.green),
        title: Text(_categoryLabels[incident.category] ?? incident.category),
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
          label: Text(incident.status, style: const TextStyle(fontSize: 11)),
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
