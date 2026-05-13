import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/widgets/map_style_layer.dart';
import 'package:flutter_app/features/admin/models/forest_model.dart';
import 'package:flutter_app/features/admin/models/parcelle_model.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

const _parcellePalette = [
  AppColors.info,
  AppColors.warning,
  AppColors.teal,
  AppColors.danger,
  AppColors.sage,
  AppColors.darkForest,
];

class ParcelleListScreen extends ConsumerWidget {
  final int forestId;
  const ParcelleListScreen({super.key, required this.forestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final forestAsync = ref.watch(forestProvider(forestId));
    final parcellesAsync = ref.watch(parcellesProvider(forestId));

    final forestName = forestAsync.whenOrNull(data: (f) => f.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          forestName != null ? '${l.parcelles}  $forestName' : l.parcelles,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l.drawParcelle),
        onPressed: () => context.go('/admin/forests/$forestId/parcelles/draw'),
      ),
      body: switch ((forestAsync, parcellesAsync)) {
        (AsyncLoading(), _) ||
        (_, AsyncLoading()) => const Center(child: CircularProgressIndicator()),
        (AsyncError(:final error), _) => _ErrorState(message: error.toString()),
        (_, AsyncError(:final error)) => _ErrorState(message: error.toString()),
        (AsyncData(:final value), AsyncData(value: final parcelles)) =>
          _ParcelleLayout(
            forest: value,
            parcelles: parcelles,
            onRefresh: () => ref.invalidate(parcellesProvider(forestId)),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

// ── Main layout ───────────────────────────────────────────────────────────────

class _ParcelleLayout extends ConsumerWidget {
  final ForestModel forest;
  final List<ParcelleModel> parcelles;
  final VoidCallback onRefresh;

  const _ParcelleLayout({
    required this.forest,
    required this.parcelles,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Row(
      children: [
        // ── Left: parcelle list ──────────────────────────────────
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${parcelles.length} ${l.parcelles}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (forest.areaHectares != null)
                      Text(
                        '${forest.areaHectares!.toStringAsFixed(0)} ${l.ha} ${l.total}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: parcelles.isEmpty
                    ? _EmptyParcelleState(
                        onDraw: () => context.go(
                          '/admin/forests/${forest.id}/parcelles/draw',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: parcelles.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        itemBuilder: (_, i) => _ParcelleTile(
                          parcelle: parcelles[i],
                          color: _parcellePalette[i % _parcellePalette.length],
                          forestId: forest.id,
                          onRefresh: onRefresh,
                        ),
                      ),
              ),
            ],
          ),
        ),

        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),

        Expanded(
          child: _OverviewMap(forest: forest, parcelles: parcelles),
        ),
      ],
    );
  }
}

// ── Parcelle tile ─────────────────────────────────────────────────────────────

class _ParcelleTile extends ConsumerWidget {
  final ParcelleModel parcelle;
  final Color color;
  final int forestId;
  final VoidCallback onRefresh;

  const _ParcelleTile({
    required this.parcelle,
    required this.color,
    required this.forestId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      title: Text(
        parcelle.name,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: parcelle.areaHectares != null
          ? Text(
              '${parcelle.areaHectares!.toStringAsFixed(1)} ${l.ha}',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: l.edit,
            color: AppColors.primaryGreen,
            onPressed: () => context.go(
              '/admin/forests/$forestId/parcelles/${parcelle.id}/edit',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: l.delete,
            color: AppColors.danger,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: Text('${l.delete} "${parcelle.name}" ?'),
                  content: Text(l.deleteParcelleWarning),
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
                await ref
                    .read(forestRepositoryProvider)
                    .deleteParcelle(forestId, parcelle.id);
                onRefresh();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Overview map ──────────────────────────────────────────────────────────────

class _OverviewMap extends StatefulWidget {
  final ForestModel forest;
  final List<ParcelleModel> parcelles;
  const _OverviewMap({required this.forest, required this.parcelles});

  @override
  State<_OverviewMap> createState() => _OverviewMapState();
}

class _OverviewMapState extends State<_OverviewMap> {
  MapStyle _mapStyle = MapStyle.plain;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final forestPoints = widget.forest.boundaryGeojson != null
        ? _geoJsonToLatLng(widget.forest.boundaryGeojson!)
        : <LatLng>[];

    final center =
        widget.forest.centerLat != null && widget.forest.centerLng != null
        ? LatLng(widget.forest.centerLat!, widget.forest.centerLng!)
        : forestPoints.isNotEmpty
        ? _centroid(forestPoints)
        : const LatLng(33.8869, 9.5375);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: forestPoints.isNotEmpty ? 11 : 8,
            minZoom: 6,
            maxZoom: 18,
            interactionOptions: InteractionOptions(
              cursorKeyboardRotationOptions:
                  CursorKeyboardRotationOptions.disabled(),
            ),
          ),
          children: [
            ...mapTileLayers(_mapStyle),
            if (forestPoints.length >= 3)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _filterValidPoints(forestPoints),
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderColor: AppColors.primaryGreen,
                    borderStrokeWidth: 2.5,
                    label: widget.forest.name,
                    labelStyle: const TextStyle(
                      color: AppColors.darkForest,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            if (widget.parcelles.isNotEmpty)
              PolygonLayer(
                polygons: widget.parcelles
                    .asMap()
                    .entries
                    .map((e) {
                      final pts = _geoJsonToLatLng(e.value.boundaryGeojson);
                      if (pts.length < 3) return null;
                      final color =
                          _parcellePalette[e.key % _parcellePalette.length];
                      return Polygon(
                        points: _filterValidPoints(pts),
                        color: color.withValues(alpha: 0.25),
                        borderColor: color,
                        borderStrokeWidth: 2,
                        label: e.value.name,
                        labelStyle: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    })
                    .where((p) => p != null)
                    .cast<Polygon>()
                    .toList(),
              ),
            mapAttributionWidget(_mapStyle),
          ],
        ),
        // ── Map style toggle ──────────────────────────────────────────────
        Positioned(
          top: 12,
          right: 12,
          child: MapStyleButton(
            current: _mapStyle,
            onChanged: (s) => setState(() => _mapStyle = s),
          ),
        ),
        if (widget.parcelles.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendRow(
                    color: AppColors.primaryGreen,
                    label: l.forestBoundary,
                    dashed: true,
                  ),
                  const SizedBox(height: 6),
                  ...widget.parcelles
                      .take(5)
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _LegendRow(
                            color:
                                _parcellePalette[e.key %
                                    _parcellePalette.length],
                            label: e.value.name,
                          ),
                        ),
                      ),
                  if (widget.parcelles.length > 5) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+ ${widget.parcelles.length - 5} ${l.others}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendRow({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyParcelleState extends StatelessWidget {
  final VoidCallback onDraw;
  const _EmptyParcelleState({required this.onDraw});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_location_alt_outlined,
            size: 52,
            color: AppColors.primaryGreen.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            l.noParcelles,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l.noParcellesHint,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(l.drawParcelle),
            onPressed: onDraw,
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 12),
          Text(l.errorOccurred, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Geometry helpers ──────────────────────────────────────────────────────────

List<LatLng> _filterValidPoints(List<LatLng> points) {
  return points
      .where(
        (p) =>
            p.latitude.isFinite &&
            p.longitude.isFinite &&
            p.latitude >= -90 &&
            p.latitude <= 90 &&
            p.longitude >= -180 &&
            p.longitude <= 180,
      )
      .toList();
}

List<LatLng> _geoJsonToLatLng(Map<String, dynamic> geojson) {
  try {
    final type = geojson['type'] as String?;
    final coordsList = geojson['coordinates'] as List?;
    if (coordsList == null || coordsList.isEmpty) return [];
    dynamic ringData;
    if (type == 'MultiPolygon') {
      if (coordsList[0] is! List || (coordsList[0] as List).isEmpty) return [];
      ringData = (coordsList[0] as List)[0];
    } else {
      ringData = coordsList[0];
    }
    if (ringData is! List) return [];
    final result = <LatLng>[];
    for (final coord in ringData) {
      if (coord is! List || (coord).length < 2) continue;
      try {
        final lng = coord[0];
        final lat = coord[1];
        if (lng is! num || lat is! num) continue;
        final latD = lat.toDouble();
        final lngD = lng.toDouble();
        if (!latD.isFinite || !lngD.isFinite) continue;
        if (latD < -90 || latD > 90 || lngD < -180 || lngD > 180) continue;
        result.add(LatLng(latD, lngD));
      } catch (_) {}
    }
    return result;
  } catch (_) {
    return [];
  }
}

LatLng _centroid(List<LatLng> pts) {
  if (pts.isEmpty) return const LatLng(33.8869, 9.5375);
  double lat = 0, lng = 0;
  for (final p in pts) {
    lat += p.latitude;
    lng += p.longitude;
  }
  return LatLng(lat / pts.length, lng / pts.length);
}
