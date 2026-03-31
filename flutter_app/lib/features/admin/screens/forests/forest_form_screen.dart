import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

const _tunisiaCenter = LatLng(33.8869, 9.5375);

class ForestFormScreen extends ConsumerStatefulWidget {
  final int? forestId;
  const ForestFormScreen({super.key, this.forestId});
  @override
  ConsumerState<ForestFormScreen> createState() => _State();
}

class _State extends ConsumerState<ForestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _mapCtrl = MapController();

  List<LatLng> _drawingPoints = [];
  bool _isDrawing = false;
  bool _loading = false;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.forestId != null) {
      _loadExisting();
    } else {
      _dataLoaded = true;
    }
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    _nameCtrl.dispose();
    _regionCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final forest = await ref
        .read(forestRepositoryProvider)
        .getForest(widget.forestId!);
    setState(() {
      _nameCtrl.text = forest.name;
      _regionCtrl.text = forest.region ?? '';
      _descCtrl.text = forest.description ?? '';
      if (forest.boundaryGeojson != null) {
        _drawingPoints = _geoJsonToLatLng(forest.boundaryGeojson!);
      }
      _dataLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.forestId != null;

    if (!_dataLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chargement…')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier la forêt' : 'Nouvelle forêt'),
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
          // ── Left: form panel ────────────────────────────────────────────────
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
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
                        labelText: 'Nom de la forêt *',
                        prefixIcon: Icon(Icons.forest_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _regionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Région',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Délimitation spatiale',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _drawingPoints.length >= 3
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _drawingPoints.length >= 3
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _drawingPoints.length >= 3
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color: _drawingPoints.length >= 3
                                ? AppColors.success
                                : AppColors.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _drawingPoints.isEmpty
                                ? 'Aucune limite définie'
                                : _drawingPoints.length < 3
                                ? '${_drawingPoints.length} point(s) — min. 3'
                                : '${_drawingPoints.length} points',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: _drawingPoints.length >= 3
                                      ? AppColors.success
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
                              : AppColors.primaryGreen,
                          side: BorderSide(
                            color: _isDrawing
                                ? AppColors.danger
                                : AppColors.primaryGreen,
                          ),
                        ),
                        icon: Icon(
                          _isDrawing ? Icons.stop : Icons.edit_location_alt,
                        ),
                        label: Text(
                          _isDrawing
                              ? 'Arrêter le dessin'
                              : 'Dessiner la limite',
                        ),
                        onPressed: () =>
                            setState(() => _isDrawing = !_isDrawing),
                      ),
                    ),
                    if (_isDrawing && _drawingPoints.length >= 3) ...[
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
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.warning,
                          ),
                          icon: const Icon(Icons.undo),
                          label: const Text('Annuler dernier point'),
                          onPressed: () =>
                              setState(() => _drawingPoints.removeLast()),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger,
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Effacer tout'),
                          onPressed: () =>
                              setState(() => _drawingPoints.clear()),
                        ),
                      ),
                    ],
                    if (_isDrawing) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Tapez sur la carte pour ajouter des points.\nMinimum 3 points pour former un polygone.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),

          // ── Right: map ──────────────────────────────────────────────────────
          // FIX: _ForestMapWidget is a StatelessWidget — it never triggers a
          // full FlutterMap rebuild when the parent state changes (drawing points,
          // isDrawing toggle).  The MapController is owned by the parent and
          // passed in so pan/zoom survive setState calls in the form panel.
          Expanded(
            child: _ForestMapWidget(
              mapController: _mapCtrl,
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'region': _regionCtrl.text.trim().isEmpty
            ? null
            : _regionCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      };
      if (_drawingPoints.length >= 3) {
        body['boundary_geojson'] = _latLngToGeoJson(_drawingPoints);
        final avgLat =
            _drawingPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
            _drawingPoints.length;
        final avgLng =
            _drawingPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
            _drawingPoints.length;
        body['center_lat'] = avgLat;
        body['center_lng'] = avgLng;
      }
      final repo = ref.read(forestRepositoryProvider);
      if (widget.forestId == null) {
        await repo.createForest(body);
      } else {
        await repo.updateForest(widget.forestId!, body);
      }
      ref.invalidate(forestsProvider);
      if (mounted) context.go('/admin/forests');
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

// ── Extracted map widget — StatelessWidget prevents full map rebuild ───────────
//
// Because FlutterMap is expensive to construct, wrapping it in its own
// StatelessWidget means Flutter can diff the widget tree and reuse the
// existing RenderObject instead of tearing down and recreating the map
// on every `setState` triggered by adding drawing points.

class _ForestMapWidget extends StatelessWidget {
  final MapController mapController;
  final List<LatLng> drawingPoints;
  final bool isDrawing;
  final void Function(LatLng) onTap;

  const _ForestMapWidget({
    required this.mapController,
    required this.drawingPoints,
    required this.isDrawing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPolygon = drawingPoints.length >= 3;

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: drawingPoints.isNotEmpty
                ? drawingPoints.first
                : _tunisiaCenter,
            initialZoom: drawingPoints.isNotEmpty ? 12 : 8,
            minZoom: 6,
            maxZoom: 18,
            onTap: isDrawing ? (_, latlng) => onTap(latlng) : null,
            interactionOptions: InteractionOptions(
              flags: isDrawing
                  ? InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom
                  : InteractiveFlag.all,
              // FIX: disable cursor/keyboard rotation to prevent scroll-wheel freeze on web
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
                        : AppColors.primaryGreen.withValues(alpha: 0.7),
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
                          color: e.key == 0
                              ? AppColors.primaryGreen
                              : Colors.white,
                          border: Border.all(
                            color: AppColors.primaryGreen,
                            width: 2,
                          ),
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
                      color: AppColors.sage,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mode dessin actif — Tapez pour ajouter des points',
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

// ── Helpers ───────────────────────────────────────────────────────────────────

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
