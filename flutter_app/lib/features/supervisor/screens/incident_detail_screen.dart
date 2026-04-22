import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/incidents/models/incident_model.dart';
import 'package:flutter_app/features/incidents/providers/geo_context_provider.dart';
import 'package:flutter_app/features/supervisor/providers/supervisor_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_app/core/widgets/app_bar_actions.dart';

// ── Label helpers (context-aware) ─────────────────────────────────────────────

Map<String, String> _categoryLabels(BuildContext context) {
  final l = context.l10n;
  return {
    'feu': l.typeIncendie,
    'coupe_illegale': l.typeCoupeIllegale,
    'refuge_suspect': l.typeRefugeSuspect,
    'trafic': l.typeTrafic,
    'dechet': l.typeDechet,
    'maladie': l.typeMaladie,
    'autre': l.typeAutre,
  };
}

Map<String, String> _statusLabels(BuildContext context) {
  final l = context.l10n;
  return {
    'pending': l.pending,
    'in_progress': l.inProgress,
    'resolved': l.resolved,
    'rejected': l.rejected,
  };
}

// ── Screen ────────────────────────────────────────────────────────────────────
class IncidentDetailScreen extends ConsumerWidget {
  final int incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(singleIncidentProvider(incidentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.incidentDetail),
        leading: const BackButton(),
        actions: kAppBarActions,
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
              Text('${l.errorPrefix} $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(singleIncidentProvider(incidentId)),
                child: Text(l.retry),
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
    final l = context.l10n;
    final updateState = ref.watch(statusUpdateProvider);

    ref.listen(statusUpdateProvider, (_, next) {
      next.whenOrNull(
        data: (_) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.incidentUpdated),
            backgroundColor: AppColors.success,
          ),
        ),
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.errorPrefix} $e'),
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

          _GeoContextCard(incident: incident),
          const SizedBox(height: 16),

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
    final l = context.l10n;
    final theme = Theme.of(context);
    final labels = _categoryLabels(context);

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
                    labels[incident.category] ?? incident.category,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          size: 14,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l.critical.toUpperCase(),
                          style: const TextStyle(
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
              label: l.agent,
              value: incident.agentName ?? l.unknown,
            ),
            _InfoRow(
              icon: Icons.access_time,
              label: l.reportedOn,
              value: DateFormat(
                'dd MMM yyyy à HH:mm',
              ).format(incident.createdAt),
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
    final labels = _statusLabels(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(.4)),
      ),
      child: Text(
        labels[status] ?? status,
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
    final l = context.l10n;
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
                  l.photo,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                const Icon(Icons.open_in_full, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  l.tapToZoom,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
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
    final l = context.l10n;
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
                  l.location,
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
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.description,
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
                l.supervisorCommentBy(incident.supervisorName ?? l.supervisor),
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
    final l = context.l10n;
    final statusLabels = _statusLabels(context);
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
              l.supervisorActions,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: l.status,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: statusLabels.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: isClosed
                  ? null
                  : (v) => setState(() => _selectedStatus = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 3,
              enabled: !isClosed,
              decoration: InputDecoration(
                labelText: l.supervisorComment,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            if (isClosed)
              Text(
                l.closedIncident,
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
                  label: Text(l.save),
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

// ── Geo context card ──────────────────────────────────────────────────────────
class _GeoContextCard extends ConsumerWidget {
  final IncidentModel incident;
  const _GeoContextCard({required this.incident});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final asyncGeo = ref.watch(geoContextProvider(incident));

    // If we know there's nothing to show yet (worker hasn't enriched),
    // show a subtle "pending enrichment" card instead of nothing.
    if (incident.geoEnrichmentStatus == 'not_found') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.location_off_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.geoContextNotFound,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (incident.geoEnrichmentStatus == 'pending') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  l.geoContextPending,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ──
            Row(
              children: [
                const Icon(Icons.park_outlined, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  l.forestContext,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Divider(height: 24),
            // ── Async content ──
            asyncGeo.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => Text(
                l.geoContextUnavailable,
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (ctx) => Column(
                children: [
                  // Forest row
                  _GeoRow(
                    icon: Icons.forest,
                    label: l.forests,
                    value: ctx.forest?.name ?? '#${incident.forestId}',
                  ),
                  if (ctx.forest?.region != null)
                    _GeoRow(
                      icon: Icons.location_on_outlined,
                      label: l.region,
                      value: ctx.forest!.region!,
                    ),
                  const Divider(height: 16),
                  // Parcelle row
                  _GeoRow(
                    icon: Icons.grid_view_outlined,
                    label: l.parcelles,
                    value:
                        ctx.parcelle?.name ??
                        (incident.parcelleId != null
                            ? '#${incident.parcelleId}'
                            : '—'),
                  ),
                  if (ctx.parcelle?.areaHectares != null)
                    _GeoRow(
                      icon: Icons.straighten_outlined,
                      label: l.area,
                      value:
                          '${ctx.parcelle!.areaHectares!.toStringAsFixed(2)} ha',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _GeoRow({required this.icon, required this.label, required this.value});

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
