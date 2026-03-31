import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class ParcelleDrawScreen extends ConsumerStatefulWidget {
  final int forestId;
  final int? parcelleId;
  const ParcelleDrawScreen({
    super.key,
    required this.forestId,
    this.parcelleId,
  });
  @override
  ConsumerState<ParcelleDrawScreen> createState() => _State();
}

class _State extends ConsumerState<ParcelleDrawScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<LatLng> _forestBoundary = [];
  List<LatLng> _drawingPoints = [];
  bool _isDrawing = false;
  bool _loading = false;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final repo = ref.read(forestRepositoryProvider);
    final forest = await repo.getForest(widget.forestId);

    if (forest.boundaryGeojson != null) {
      _forestBoundary = _geoJsonToLatLng(forest.boundaryGeojson!);
    }
    if (widget.parcelleId != null) {
      final parcelles = await repo.getParcelles(widget.forestId);
      final existing = parcelles
          .where((p) => p.id == widget.parcelleId)
          .firstOrNull;
      if (existing != null) {
        _nameCtrl.text = existing.name;
        _descCtrl.text = existing.description ?? '';
        _drawingPoints = _geoJsonToLatLng(existing.boundaryGeojson);
      }
    }
    setState(() => _dataLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chargement…')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isEdit = widget.parcelleId != null;
    final hasPolygon = _drawingPoints.length >= 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier la parcelle' : 'Nouvelle parcelle'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              icon: _loading
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
              onPressed: _loading ? null : _save,
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // ── Left: form ───────────────────────────────────────
          SizedBox(
            width: 280,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la parcelle *',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Délimitation de la parcelle',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: hasPolygon
                          ? AppColors.info.withValues(
                              alpha: 0.1,
                            ) // parcelle = info blue
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasPolygon ? AppColors.info : AppColors.warning,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasPolygon
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          color: hasPolygon
                              ? AppColors.info
                              : AppColors.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _drawingPoints.isEmpty
                              ? 'Aucun polygone dessiné'
                              : '${_drawingPoints.length} points',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: hasPolygon
                                    ? AppColors.info
                                    : AppColors.warning,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isDrawing
                            ? AppColors.danger
                            : AppColors.info,
                        side: BorderSide(
                          color: _isDrawing ? AppColors.danger : AppColors.info,
                        ),
                      ),
                      icon: Icon(
                        _isDrawing ? Icons.stop : Icons.edit_location_alt,
                      ),
                      label: Text(_isDrawing ? 'Arrêter' : 'Dessiner'),
                      onPressed: () => setState(() => _isDrawing = !_isDrawing),
                    ),
                  ),

                  if (_isDrawing && hasPolygon) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Fermer le polygone'),
                        onPressed: () => setState(() => _isDrawing = false),
                      ),
                    ),
                  ],

                  if (_drawingPoints.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.warning,
                      ),
                      icon: const Icon(Icons.undo),
                      label: const Text('Dernier point'),
                      onPressed: () =>
                          setState(() => _drawingPoints.removeLast()),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Effacer tout'),
                      onPressed: () => setState(() => _drawingPoints.clear()),
                    ),
                  ],

                  const SizedBox(height: 20),
                  // Reference legend
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Légende',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        _LegendItem(
                          color: AppColors.primaryGreen,
                          label: 'Limite forêt parente',
                        ),
                        const SizedBox(height: 4),
                        _LegendItem(
                          color: AppColors.info,
                          label: 'Parcelle en cours',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),

          // ── Right: map ───────────────────────────────────────
          Expanded(
            child: _ParcelleDrawMapWidget(
              forestBoundary: _forestBoundary,
              drawingPoints: _drawingPoints,
              isDrawing: _isDrawing,
              onTap: (latlng) => setState(() => _drawingPoints.add(latlng)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Le nom est obligatoire')));
      return;
    }
    if (_drawingPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dessinez au moins 3 points')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final body = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'boundary_geojson': _latLngToGeoJson(_drawingPoints),
      };
      final repo = ref.read(forestRepositoryProvider);
      if (widget.parcelleId == null) {
        await repo.createParcelle(widget.forestId, body);
      } else {
        await repo.updateParcelle(widget.forestId, widget.parcelleId!, body);
      }
      ref.invalidate(parcellesProvider(widget.forestId));
      if (mounted) context.go('/admin/forests/${widget.forestId}/parcelles');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Extracted draw map widget — StatelessWidget prevents full map rebuild ─────
//
// Receives immutable snapshots of drawingPoints, forestBoundary, and isDrawing.
// Flutter diffs the widget tree and reuses the existing FlutterMap render
// object instead of tearing it down on every setState in the parent.
// Also adds cursorKeyboardRotationOptions.disabled() which was missing,
// preventing the scroll-wheel freeze on Flutter Web.

class _ParcelleDrawMapWidget extends StatelessWidget {
  final List<LatLng> forestBoundary;
  final List<LatLng> drawingPoints;
  final bool isDrawing;
  final void Function(LatLng) onTap;

  const _ParcelleDrawMapWidget({
    required this.forestBoundary,
    required this.drawingPoints,
    required this.isDrawing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPolygon = drawingPoints.length >= 3;
    final centerLL = forestBoundary.isNotEmpty
        ? forestBoundary.first
        : const LatLng(33.8869, 9.5375);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: centerLL,
            initialZoom: forestBoundary.isNotEmpty ? 12 : 8,
            minZoom: 6,
            maxZoom: 18,

            onTap: isDrawing ? (_, ll) => onTap(ll) : null,
            interactionOptions: InteractionOptions(
              flags: isDrawing
                  ? InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom
                  : InteractiveFlag.all,
              // FIX: was missing entirely — causes scroll-wheel freeze on web
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
            // Parent forest boundary — green reference outline
            if (forestBoundary.length >= 3)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: forestBoundary,
                    color: AppColors.primaryGreen.withValues(alpha: 0.06),
                    borderColor: AppColors.primaryGreen,
                    borderStrokeWidth: 3,
                    label: 'Limite forêt',
                    labelStyle: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            // Parcelle polygon — info blue
            if (hasPolygon)
              PolygonLayer(
                polygons: [
                  if (drawingPoints.length >= 3)
                    Polygon(
                      points: _filterValidPoints(drawingPoints),
                      color: AppColors.primaryGreen.withValues(alpha: 0.2),
                      borderColor: AppColors.primaryGreen,
                      borderStrokeWidth: 2.5,
                    ),
                ],
              ),
            if (drawingPoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _filterValidPoints([
                      ...drawingPoints,
                      if (isDrawing) drawingPoints.first,
                    ]),
                    color: !hasPolygon
                        ? AppColors.warning.withValues(alpha: 0.7)
                        : AppColors.info.withValues(alpha: 0.7),
                    strokeWidth: !hasPolygon ? 1.5 : 2.0,
                  ),
                ],
              ),
            MarkerLayer(
              markers: drawingPoints
                  .asMap()
                  .entries
                  .map(
                    (e) => Marker(
                      point: e.value,
                      width: 14,
                      height: 14,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: e.key == 0 ? AppColors.info : Colors.white,
                          border: Border.all(color: AppColors.info, width: 2),
                        ),
                      ),
                    ),
                  )
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
        if (isDrawing)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkBg.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.touch_app,
                      color: AppColors.info,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tapez dans la forêt pour ajouter des points',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Legend item ───────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

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

Map<String, dynamic> _latLngToGeoJson(List<LatLng> points) {
  final coords = [
    ...points.map((p) => [p.longitude, p.latitude]),
    [points.first.longitude, points.first.latitude],
  ];
  return {
    'type': 'Polygon',
    'coordinates': [coords],
  };
}
