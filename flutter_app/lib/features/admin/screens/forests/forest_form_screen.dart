import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/admin/models/forest_model.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_app/core/widgets/app_bar_actions.dart';

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
  // All forests already saved, excluding the one currently being edited.
  List<ForestModel> _existingForests = [];
  bool _isDrawing = false;
  bool _loading = false;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    // Always run async load — even for create mode we need the forest list
    // to show existing boundaries on the map.
    _loadData();
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    _nameCtrl.dispose();
    _regionCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // ── 1. All forests (via Riverpod cache) ────────────────────────────────
    //
    // ref.read(forestsProvider.future) reuses whatever is already in the
    // Riverpod cache (e.g. loaded by the forest list screen). Zero extra
    // network calls if the data is already warm.
    final allForests = await ref.read(forestsProvider.future);

    // Keep only the forests that are NOT the one being edited so we don't
    // render the current drawing twice on the map.
    _existingForests = allForests
        .where((f) => f.id != widget.forestId)
        .toList();

    // ── 2. Pre-populate form when editing ──────────────────────────────────
    if (widget.forestId != null) {
      // Re-use the already-fetched list instead of making a second call.
      final current = allForests
          .where((f) => f.id == widget.forestId)
          .firstOrNull;

      // Fallback: if for some reason it wasn't in the list (e.g. stale cache
      // before the forest was created), hit the endpoint directly.
      final forest =
          current ??
          await ref.read(forestRepositoryProvider).getForest(widget.forestId!);

      _nameCtrl.text = forest.name;
      _regionCtrl.text = forest.region ?? '';
      _descCtrl.text = forest.description ?? '';
      if (forest.boundaryGeojson != null) {
        _drawingPoints = _geoJsonToLatLng(forest.boundaryGeojson!);
      }
    }

    setState(() => _dataLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isEdit = widget.forestId != null;

    if (!_dataLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text(l.loading), actions: kAppBarActions),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l.editForest : l.newForest),
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
              label: Text(l.save),
              onPressed: _loading ? null : _save,
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // ── Left: form panel ──────────────────────────────────────────────
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
                      l.information,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l.forestNameLabel,
                        prefixIcon: const Icon(Icons.forest_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? l.required : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _regionCtrl,
                      decoration: InputDecoration(
                        labelText: l.region,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: InputDecoration(
                        labelText: l.description,
                        prefixIcon: const Icon(Icons.notes_outlined),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l.spatialBoundary,
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
                                ? l.noBoundaryDefined
                                : _drawingPoints.length < 3
                                ? '${_drawingPoints.length} ${l.pointsMinThree}'
                                : '${_drawingPoints.length} ${l.points}',
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
                          _isDrawing ? l.stopDrawing : l.drawBoundary,
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
                          label: Text(l.closePolygon),
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
                          label: Text(l.undoLastPoint),
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
                          label: Text(l.clearAll),
                          onPressed: () =>
                              setState(() => _drawingPoints.clear()),
                        ),
                      ),
                    ],

                    if (_isDrawing) ...[
                      const SizedBox(height: 16),
                      Text(
                        l.drawingHint,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Legend ──────────────────────────────────────────────
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
                            l.legend,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          // New key — see ARB changes below
                          _LegendItem(
                            color: Colors.orange,
                            label: l.existingForests,
                          ),
                          const SizedBox(height: 4),
                          // New key — see ARB changes below
                          _LegendItem(
                            color: AppColors.primaryGreen,
                            label: l.currentForestBoundary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),

          // ── Right: map ────────────────────────────────────────────────────
          Expanded(
            child: _ForestMapWidget(
              mapController: _mapCtrl,
              existingForests: _existingForests,
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
    final l = context.l10n;
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
            content: Text('${l.errorPrefix} $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Extracted map widget ──────────────────────────────────────────────────────

class _ForestMapWidget extends StatelessWidget {
  final MapController mapController;
  final List<ForestModel> existingForests;
  final List<LatLng> drawingPoints;
  final bool isDrawing;
  final void Function(LatLng) onTap;

  const _ForestMapWidget({
    required this.mapController,
    required this.existingForests,
    required this.drawingPoints,
    required this.isDrawing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hasPolygon = drawingPoints.length >= 3;

    // Pre-convert existing forest boundaries so we don't re-parse GeoJSON on
    // every repaint triggered by drawing points being added.
    final existingPolygons = existingForests
        .where((f) => f.boundaryGeojson != null)
        .map((f) => _geoJsonToLatLng(f.boundaryGeojson!))
        .where((pts) => pts.length >= 3)
        .toList();

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
              cursorKeyboardRotationOptions:
                  CursorKeyboardRotationOptions.disabled(),
            ),
          ),
          children: [
            // ── Base tile layer ───────────────────────────────────────────
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ghabetna.app',
              maxZoom: 19,
            ),

            // ── Existing forests overlay ──────────────────────────────────
            //
            // Rendered below the active drawing so the user always sees their
            // own polygon on top. Orange makes them visually distinct from the
            // current forest being drawn (green).
            if (existingPolygons.isNotEmpty)
              PolygonLayer(
                polygons: existingPolygons
                    .map(
                      (pts) => Polygon(
                        points: pts,
                        color: Colors.orange.withValues(alpha: 0.18),
                        borderColor: Colors.orange,
                        borderStrokeWidth: 1.5,
                      ),
                    )
                    .toList(),
              ),

            // ── Current drawing: filled polygon (≥ 3 pts) ─────────────────
            if (hasPolygon)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _filterValidPoints(drawingPoints),
                    color: AppColors.primaryGreen.withValues(alpha: 0.2),
                    borderColor: AppColors.primaryGreen,
                    borderStrokeWidth: 2.5,
                  ),
                ],
              ),

            // ── Current drawing: outline while < 3 pts ────────────────────
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

            // ── Vertex markers ────────────────────────────────────────────
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

        // ── Drawing mode hint banner ──────────────────────────────────────
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
                      l.drawingModeActive,
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

// ── Helpers ───────────────────────────────────────────────────────────────────

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
