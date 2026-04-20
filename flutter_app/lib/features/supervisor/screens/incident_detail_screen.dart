import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/incidents/models/incident_model.dart';
import 'package:flutter_app/features/supervisor/providers/supervisor_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

// ── Labels ────────────────────────────────────────────────────────────────────
const _categoryLabels = {
  'feu': 'Incendie',
  'coupe_illegale': 'Coupe illégale',
  'refuge_suspect': 'Refuge suspect',
  'trafic': 'Trafic',
  'dechet': 'Déchets',
  'maladie': 'Maladie végétale',
  'autre': 'Autre',
};

const _statusLabels = {
  'pending': 'En attente',
  'in_progress': 'En cours',
  'resolved': 'Résolu',
  'rejected': 'Rejeté',
};

// ── Screen ────────────────────────────────────────────────────────────────────
class IncidentDetailScreen extends ConsumerWidget {
  final int incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(singleIncidentProvider(incidentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'incident'),
        leading: const BackButton(),
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
              Text('Erreur: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(singleIncidentProvider(incidentId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (incident) => _IncidentDetail(incident: incident),
      ),
    );
  }
}

// ── Main content ──────────────────────────────────────────────────────────────
class _IncidentDetail extends ConsumerWidget {
  final IncidentModel incident;
  const _IncidentDetail({required this.incident});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(statusUpdateProvider);

    // Show a snackbar when update succeeds or fails
    ref.listen(statusUpdateProvider, (_, next) {
      next.whenOrNull(
        data: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident mis à jour'),
            backgroundColor: AppColors.success,
          ),
        ),
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.danger,
          ),
        ),
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(incident: incident),
          const SizedBox(height: 16),
          if (incident.imageUrl != null) ...[
            _ImageCard(imageUrl: incident.imageUrl!),
            const SizedBox(height: 16),
          ],
          if (incident.latitude != null && incident.longitude != null) ...[
            _MapCard(lat: incident.latitude!, lng: incident.longitude!),
            const SizedBox(height: 16),
          ],
          _DescriptionCard(incident: incident),
          const SizedBox(height: 16),
          _SupervisorActionCard(
            incident: incident,
            isLoading: updateState.isLoading,
          ),
        ],
      ),
    );
  }
}

// ── Header card ───────────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final IncidentModel incident;
  const _HeaderCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _categoryLabels[incident.category] ?? incident.category,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (incident.isCritical)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 14,
                          color: AppColors.danger,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'CRITIQUE',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Agent',
              value: incident.agentName ?? 'Inconnu',
            ),
            _InfoRow(
              icon: Icons.access_time,
              label: 'Signalé le',
              value: DateFormat(
                'dd MMM yyyy à HH:mm',
              ).format(incident.createdAt),
            ),
            if (incident.parcelleId != null)
              _InfoRow(
                icon: Icons.grid_view,
                label: 'Parcelle',
                value: '#${incident.parcelleId}',
              ),
            if (incident.forestId != null)
              _InfoRow(
                icon: Icons.forest,
                label: 'Forêt',
                value: '#${incident.forestId}',
              ),
            const SizedBox(height: 12),
            _StatusChip(status: incident.status),
          ],
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color => switch (status) {
    'pending' => AppColors.warning,
    'in_progress' => AppColors.info,
    'resolved' => AppColors.success,
    'rejected' => AppColors.danger,
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(.4)),
      ),
      child: Text(
        _statusLabels[status] ?? status,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── Image card ────────────────────────────────────────────────────────────────
class _ImageCard extends StatelessWidget {
  final String imageUrl;
  const _ImageCard({required this.imageUrl});

  void _openFullscreen(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.white38,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'Photo',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                const Icon(Icons.open_in_full, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                const Text(
                  'Appuyer pour agrandir',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _openFullscreen(context),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, _) {
                  if (frame == null) {
                    return const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return child;
                },
                errorBuilder: (_, error, __) {
                  debugPrint('Image load error for $imageUrl: $error');
                  return const SizedBox(
                    height: 80,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map card ──────────────────────────────────────────────────────────────────
class _MapCard extends StatelessWidget {
  final double lat, lng;
  const _MapCard({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'Localisation',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(initialCenter: point, initialZoom: 14),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppColors.danger,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Description card ──────────────────────────────────────────────────────────
class _DescriptionCard extends StatelessWidget {
  final IncidentModel incident;
  const _DescriptionCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              incident.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (incident.supervisorComment != null) ...[
              const Divider(height: 24),
              Text(
                'Commentaire superviseur',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(.25)),
                ),
                child: Text(incident.supervisorComment!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Supervisor action card ────────────────────────────────────────────────────
class _SupervisorActionCard extends ConsumerStatefulWidget {
  final IncidentModel incident;
  final bool isLoading;
  const _SupervisorActionCard({
    required this.incident,
    required this.isLoading,
  });

  @override
  ConsumerState<_SupervisorActionCard> createState() =>
      _SupervisorActionCardState();
}

class _SupervisorActionCardState extends ConsumerState<_SupervisorActionCard> {
  late String _selectedStatus;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.incident.status;
    _commentController.text = widget.incident.supervisorComment ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _save() {
    ref
        .read(statusUpdateProvider.notifier)
        .update(
          widget.incident.id,
          _selectedStatus,
          comment: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Only show actions if incident is not already closed
    final isClosed =
        widget.incident.status == 'resolved' ||
        widget.incident.status == 'rejected';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions superviseur',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('En attente')),
                DropdownMenuItem(value: 'in_progress', child: Text('En cours')),
                DropdownMenuItem(value: 'resolved', child: Text('Résolu')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejeté')),
              ],
              onChanged: isClosed
                  ? null
                  : (v) => setState(() => _selectedStatus = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 3,
              enabled: !isClosed,
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            if (isClosed)
              Text(
                'Cet incident est clôturé.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.isLoading ? null : _save,
                  icon: widget.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable info row ─────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label : ',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
