import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/widgets/app_bar_actions.dart';
import 'package:flutter_app/features/admin/models/forest_model.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_app/features/incidents/models/incident_model.dart';
import 'package:flutter_app/features/supervisor/providers/supervisor_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

const _categoryIcons = {
  'feu': Icons.local_fire_department,
  'coupe_illegale': Icons.carpenter_outlined,
  'refuge_suspect': Icons.warning_amber,
  'trafic': Icons.directions_car,
  'dechet': Icons.delete_outline,
  'maladie': Icons.coronavirus_outlined,
  'autre': Icons.report_outlined,
};

Color _markerColor(IncidentModel i) {
  return switch (i.status) {
    'pending' => AppColors.warning,
    'in_progress' => AppColors.info,
    'resolved' => AppColors.success,
    'rejected' => AppColors.danger,
    _ => Colors.grey,
  };
}

class SupervisorMapScreen extends ConsumerWidget {
  const SupervisorMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final incidentsAsync = ref.watch(allIncidentsProvider);
    final forestsAsync = ref.watch(forestsProvider); // ← new

    return Scaffold(
      appBar: AppBar(
        title: Text('${l.map} ${l.incidents}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: l.listView,
            onPressed: () => context.go('/supervisor/incidents'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allIncidentsProvider);
              ref.invalidate(forestsProvider);
            },
          ),
          ...kAppBarActions,
        ],
      ),
      body: incidentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l.errorPrefix} $e')),
        data: (incidents) {
          final mapped = incidents
              .where((i) => i.latitude != null && i.longitude != null)
              .toList();

          final center = mapped.isEmpty
              ? const LatLng(33.8869, 9.5375)
              : LatLng(
                  mapped.map((i) => i.latitude!).reduce((a, b) => a + b) /
                      mapped.length,
                  mapped.map((i) => i.longitude!).reduce((a, b) => a + b) /
                      mapped.length,
                );

          // ── Parse assigned forest boundaries (silently skip if still loading) ──
          final forests = forestsAsync.valueOrNull ?? <ForestModel>[];
          final forestPolygons = forests
              .where((f) => f.boundaryGeojson != null)
              .map((f) => _geoJsonToLatLng(f.boundaryGeojson!))
              .where((pts) => pts.length >= 3)
              .toList();

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: mapped.isEmpty ? 6.5 : 9,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ghabetna.app',
                  ),

                  // ── Forest outlines ──────────────────────────────────────
                  if (forestPolygons.isNotEmpty)
                    PolygonLayer(
                      polygons: forestPolygons
                          .map(
                            (pts) => Polygon(
                              points: pts,
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.06,
                              ),
                              borderColor: AppColors.primaryGreen,
                              borderStrokeWidth: 3,
                            ),
                          )
                          .toList(),
                    ),
                  MarkerLayer(
                    markers: mapped.map((incident) {
                      final color = _markerColor(incident);
                      final icon =
                          _categoryIcons[incident.category] ?? Icons.report;
                      return Marker(
                        point: LatLng(incident.latitude!, incident.longitude!),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => context.push(
                            '/supervisor/incidents/${incident.id}',
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: .4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              if (incident.isCritical)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              //legend
              Positioned(bottom: 24, right: 16, child: _MapLegend()),
              // counter badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Text(
                    '${mapped.length} ${l.incidents}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.legend,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 6),
          _LegendItem(color: AppColors.warning, label: l.pending),
          _LegendItem(color: AppColors.info, label: l.inProgress),
          _LegendItem(color: AppColors.success, label: l.resolved),
          _LegendItem(color: AppColors.danger, label: l.rejected),
          const SizedBox(height: 4),
          _CriticalLegendItem(),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _CriticalLegendItem extends StatelessWidget {
  const _CriticalLegendItem();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 5,
            backgroundColor: AppColors.danger,
            child: const Icon(
              Icons.priority_high,
              size: 7,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(l.critical, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
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
