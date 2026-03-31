import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/admin/models/forest_model.dart';
import 'package:flutter_app/features/admin/models/parcelle_model.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

// A distinct palette for parcelles — using AppColors as base, no raw Color()

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
    final forestAsync = ref.watch(forestProvider(forestId));
    final parcellesAsync = ref.watch(parcellesProvider(forestId));

    // Resolve forest name for AppBar while loading
    final forestName = forestAsync.whenOrNull(data: (f) => f.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          forestName != null ? 'Parcelles — $forestName' : 'Parcelles',
        ),
        // Back arrow automatically goes to /admin/forests via go_router shell
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Dessiner une parcelle'),
        onPressed: () => context.go('/admin/forests/$forestId/parcelles/draw'),
      ),
      body: switch ((forestAsync, parcellesAsync)) {
        // Both loading
        (AsyncLoading(), _) ||
        (_, AsyncLoading()) => const Center(child: CircularProgressIndicator()),
        // Any error
        (AsyncError(:final error), _) => _ErrorState(message: error.toString()),
        (_, AsyncError(:final error)) => _ErrorState(message: error.toString()),
        // Both data
        (AsyncData(:final value), AsyncData(value: final parcelles)) =>
          _ParcelleLayout(
            forest: value,
            parcelles: parcelles,
            onRefresh: () {
              ref.invalidate(parcellesProvider(forestId));
            },
          ),
        // Fallback (should never happen)
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

// ── Main layout: list on left, map on right ───────────────────────────────────

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
    return Row(
      children: [
        // ── Left: parcelle list ──────────────────────────────────
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                      '${parcelles.length} parcelle${parcelles.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (forest.areaHectares != null)
                      Text(
                        '${forest.areaHectares!.toStringAsFixed(0)} ha total',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              // List
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
                        separatorBuilder: (_, _) => Divider(
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

        // Vertical divider
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),

        // ── Right: overview map ─────────────────────────────────────────────
        // FIX: _OverviewMap is already a StatelessWidget — good. But it was
        // missing cursorKeyboardRotationOptions (scroll-wheel freeze on web).
        Expanded(
          child: _OverviewMap(forest: forest, parcelles: parcelles),
        ),
      ],
    );
  }
}

// ── Parcelle tile ──────────────────────────────────────────────────────────────

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
              '${parcelle.areaHectares!.toStringAsFixed(1)} ha',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Modifier',
            color: AppColors.primaryGreen,
            onPressed: () => context.go(
              '/admin/forests/$forestId/parcelles/${parcelle.id}/edit',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Supprimer',
            color: AppColors.danger,
            onPressed: () async {
              // FIX: use dialogCtx so Navigator.pop targets the dialog overlay,
              // not the GoRouter navigation stack (which causes blank page crash).
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: Text('Supprimer "${parcelle.name}" ?'),
                  content: const Text(
                    'Cette parcelle sera supprimée définitivement.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      ),
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      child: const Text('Supprimer'),
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

// ── Overview map — StatelessWidget, receives data as props ────────────────────
//
// FIX: added cursorKeyboardRotationOptions: CursorKeyboardRotationOptions.disabled()
// to InteractionOptions to prevent scroll-wheel freeze on Flutter Web.

class _OverviewMap extends StatelessWidget {
  final ForestModel forest;
  final List<ParcelleModel> parcelles;
  const _OverviewMap({required this.forest, required this.parcelles});

  @override
  Widget build(BuildContext context) {
    final forestPoints = forest.boundaryGeojson != null
        ? _geoJsonToLatLng(forest.boundaryGeojson!)
        : <LatLng>[];

    final center = forest.centerLat != null && forest.centerLng != null
        ? LatLng(forest.centerLat!, forest.centerLng!)
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
              // FIX: disables the cursor/keyboard rotation that causes
              // scroll-wheel events to freeze the map on web
              cursorKeyboardRotationOptions:
                  CursorKeyboardRotationOptions.disabled(),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ghabetna.app',
              maxZoom: 19,
            ),
            // Forest boundary — primaryGreen outline
            if (forestPoints.length >= 3)
              PolygonLayer(
                polygons: [
                  if (forestPoints.length >= 3)
                    Polygon(
                      points: _filterValidPoints(forestPoints),
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                      borderColor: AppColors.primaryGreen,
                      borderStrokeWidth: 2.5,
                      label: forest.name,
                      labelStyle: const TextStyle(
                        color: AppColors.darkForest,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            // Parcelles — each with its palette color
            if (parcelles.isNotEmpty)
              PolygonLayer(
                polygons: parcelles.asMap().entries
                    .map((e) {
                      final pts = _geoJsonToLatLng(e.value.boundaryGeojson);
                      // Skip invalid polygons with fewer than 3 points
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
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Legend overlay — bottom-left
        if (parcelles.isNotEmpty)
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
                    label: 'Limite forêt',
                    dashed: true,
                  ),
                  const SizedBox(height: 6),
                  ...parcelles
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
                  if (parcelles.length > 5) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+ ${parcelles.length - 5} autres',
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
            'Aucune parcelle',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Dessinez des zones de patrouille à l\'intérieur de cette forêt.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Dessiner une parcelle'),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 12),
          Text(
            'Une erreur est survenue',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
      .where((p) =>
          p.latitude.isFinite &&
          p.longitude.isFinite &&
          p.latitude >= -90 &&
          p.latitude <= 90 &&
          p.longitude >= -180 &&
          p.longitude <= 180)
      .toList();
}

List<LatLng> _geoJsonToLatLng(Map<String, dynamic> geojson) {
  try {
    final type = geojson['type'] as String?;
    final coordsList = geojson['coordinates'] as List?;
    
    if (coordsList == null || coordsList.isEmpty) {
      return [];
    }
    
    // Handle both Polygon and MultiPolygon formats
    dynamic ringData;
    
    if (type == 'MultiPolygon') {
      // For MultiPolygon, get the first polygon, then its exterior ring
      if (coordsList[0] is! List || (coordsList[0] as List).isEmpty) {
        return [];
      }
      ringData = (coordsList[0] as List)[0];
    } else {
      // For Polygon, get the exterior ring directly
      ringData = coordsList[0];
    }
    
    if (ringData is! List) {
      return [];
    }
    
    final ring = ringData;
    
    // Convert coordinate pairs [lon, lat] to LatLng(lat, lon)
    final result = <LatLng>[];
    for (final coord in ring) {
      if (coord is! List || (coord).length < 2) continue;
      
      try {
        final lng = coord[0];
        final lat = coord[1];
        
        if (lng is! num || lat is! num) continue;
        
        final latDouble = lat.toDouble();
        final lngDouble = lng.toDouble();
        
        // Skip invalid coordinates
        if (!latDouble.isFinite || !lngDouble.isFinite) continue;
        if (latDouble < -90 || latDouble > 90) continue;
        if (lngDouble < -180 || lngDouble > 180) continue;
        
        result.add(LatLng(latDouble, lngDouble));
      } catch (_) {
        // Skip any invalid coordinate
      }
    }
    
    return result;
  } catch (e) {
    // Return empty list if anything goes wrong
    return [];
  }
}

LatLng _centroid(List<LatLng> pts) {
  if (pts.isEmpty) {
    return const LatLng(33.8869, 9.5375); // Default to Tunisia center
  }
  double lat = 0, lng = 0;
  for (final p in pts) {
    lat += p.latitude;
    lng += p.longitude;
  }
  return LatLng(lat / pts.length, lng / pts.length);
}
