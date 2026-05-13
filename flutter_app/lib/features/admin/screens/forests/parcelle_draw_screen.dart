import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/utils/polygon_utils.dart';
import 'package:flutter_app/core/widgets/map_style_layer.dart';
import 'package:flutter_app/features/admin/models/parcelle_model.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

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
  // All sibling parcelles already saved in this forest (excluding the one
  // currently being edited so we don't show it twice).
  List<ParcelleModel> _existingParcelles = [];
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

    // ── 1. Forest boundary ──────────────────────────────────────────────────
    final forest = await repo.getForest(widget.forestId);
    if (forest.boundaryGeojson != null) {
      _forestBoundary = _geoJsonToLatLng(forest.boundaryGeojson!);
    }

    // ── 2. All parcelles for this forest (via Riverpod cache) ───────────────
    //
    // Using ref.read(parcellesProvider(...).future) means:
    //   • If the parcelle list was already loaded elsewhere (e.g. parcelle list
    //     screen), Riverpod serves the cached value — zero extra network calls.
    //   • If it hasn't been loaded yet, it fetches once and the result stays
    //     cached for the lifetime of the provider.
    //
    // This is the Flutter-idiomatic equivalent of the "JS in-memory cache"
    // pattern: no manual caching, no JS interop needed.
    final allParcelles = await ref.read(
      parcellesProvider(widget.forestId).future,
    );

    // Keep only the parcelles that are NOT the one being edited so we don't
    // render a duplicate of the polygon the user is actively drawing.
    _existingParcelles = allParcelles
        .where((p) => p.id != widget.parcelleId)
        .toList();

    // ── 3. Pre-populate form when editing ───────────────────────────────────
    if (widget.parcelleId != null) {
      final existing = allParcelles
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
    final l = context.l10n;

    if (!_dataLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text(l.loading)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isEdit = widget.parcelleId != null;
    final hasPolygon = _drawingPoints.length >= 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l.editParcelle : l.newParcelle),
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
          // ── Left: form ───────────────────────────────────────
          SizedBox(
            width: 280,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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
                      labelText: l.parcelleNameLabel,
                      prefixIcon: const Icon(Icons.map_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: InputDecoration(
                      labelText: l.description,
                      prefixIcon: const Icon(Icons.notes_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l.parcelleBoundary,
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
                          ? AppColors.info.withValues(alpha: 0.1)
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
                              ? l.noPolygonDrawn
                              : '${_drawingPoints.length} ${l.points}',
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
                      label: Text(_isDrawing ? l.stopDrawing : l.drawBoundary),
                      onPressed: () => setState(() => _isDrawing = !_isDrawing),
                    ),
                  ),

                  if (_isDrawing && hasPolygon) ...[
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
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.warning,
                      ),
                      icon: const Icon(Icons.undo),
                      label: Text(l.undoLastPoint),
                      onPressed: () =>
                          setState(() => _drawingPoints.removeLast()),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l.clearAll),
                      onPressed: () => setState(() => _drawingPoints.clear()),
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
                        _LegendItem(
                          color: AppColors.primaryGreen,
                          label: l.parentForestBoundary,
                        ),
                        const SizedBox(height: 4),
                        _LegendItem(
                          color: Colors.orange,
                          label: l.existingParcelles,
                        ),
                        const SizedBox(height: 4),
                        _LegendItem(
                          color: AppColors.info,
                          label: l.currentParcelle,
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
              existingParcelles: _existingParcelles,
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
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.nameRequired)));
      return;
    }
    if (_drawingPoints.length < 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.minThreePoints)));
      return;
    }
    // ── Client-side overlap check (zero DB queries) ──────────────────────────
    final newPolygon = _drawingPoints;
    for (final existing in _existingParcelles) {
      final existingPoints = _geoJsonToLatLng(existing.boundaryGeojson);
      if (polygonsOverlap(newPolygon, existingPoints)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.parcelleOverlapError(existing.name)),
            backgroundColor: AppColors.danger,
          ),
        );
        return; // bail out before touching the network
      }
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
      // Invalidate the cache so the list screen and any future draw sessions
      // reflect the newly saved parcelle.
      ref.invalidate(parcellesProvider(widget.forestId));
      if (mounted) context.go('/admin/forests/${widget.forestId}/parcelles');
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.errorPrefix} $message'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Extracted draw map widget ─────────────────────────────────────────────────

class _ParcelleDrawMapWidget extends StatefulWidget {
  final List<LatLng> forestBoundary;
  final List<ParcelleModel> existingParcelles;
  final List<LatLng> drawingPoints;
  final bool isDrawing;
  final void Function(LatLng) onTap;

  const _ParcelleDrawMapWidget({
    required this.forestBoundary,
    required this.existingParcelles,
    required this.drawingPoints,
    required this.isDrawing,
    required this.onTap,
  });

  @override
  State<_ParcelleDrawMapWidget> createState() => _ParcelleDrawMapWidgetState();
}

class _ParcelleDrawMapWidgetState extends State<_ParcelleDrawMapWidget> {
  MapStyle _mapStyle = MapStyle.plain;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hasPolygon = widget.drawingPoints.length >= 3;
    final centerLL = widget.forestBoundary.isNotEmpty
        ? widget.forestBoundary.first
        : const LatLng(33.8869, 9.5375);

    // Pre-convert existing parcelle boundaries outside the build tree so we
    // don't re-parse GeoJSON on every repaint.
    final existingPolygons = widget.existingParcelles
        .map((p) => _geoJsonToLatLng(p.boundaryGeojson))
        .where((pts) => pts.length >= 3)
        .toList();

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: centerLL,
            initialZoom: widget.forestBoundary.isNotEmpty ? 12 : 8,
            minZoom: 6,
            maxZoom: 18,
            onTap: widget.isDrawing ? (_, ll) => widget.onTap(ll) : null,
            interactionOptions: InteractionOptions(
              flags: widget.isDrawing
                  ? InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom
                  : InteractiveFlag.all,
              cursorKeyboardRotationOptions:
                  CursorKeyboardRotationOptions.disabled(),
            ),
          ),
          children: [
            ...mapTileLayers(_mapStyle),

            // ── Forest boundary ─────────────────────────────────────────────
            if (widget.forestBoundary.length >= 3)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: widget.forestBoundary,
                    color: AppColors.primaryGreen.withValues(alpha: 0.06),
                    borderColor: AppColors.primaryGreen,
                    borderStrokeWidth: 3,
                    label: l.forestBoundary,
                    labelStyle: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

            // ── Existing parcelles overlay ──────────────────────────────────
            //
            // Rendered below the active drawing so the user can always see
            // what they're drawing on top. Orange fill + border makes them
            // visually distinct from both the forest boundary (green) and the
            // current parcelle being drawn (blue).
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

            // ── Current drawing: filled polygon (≥ 3 pts) ──────────────────
            if (hasPolygon)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _filterValidPoints(widget.drawingPoints),
                    color: AppColors.info.withValues(alpha: 0.2),
                    borderColor: AppColors.info,
                    borderStrokeWidth: 2.5,
                  ),
                ],
              ),

            // ── Current drawing: outline while < 3 pts ─────────────────────
            if (widget.drawingPoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _filterValidPoints([
                      ...widget.drawingPoints,
                      if (widget.isDrawing) widget.drawingPoints.first,
                    ]),
                    color: !hasPolygon
                        ? AppColors.warning.withValues(alpha: 0.7)
                        : AppColors.info.withValues(alpha: 0.7),
                    strokeWidth: !hasPolygon ? 1.5 : 2.0,
                  ),
                ],
              ),

            // ── Vertex markers ──────────────────────────────────────────────
            MarkerLayer(
              markers: widget.drawingPoints
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

        // ── Drawing mode hint banner ────────────────────────────────────────
        if (widget.isDrawing)
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
                      l.drawingInsideForestHint,
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
      if (coord is! List || coord.length < 2) continue;
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
