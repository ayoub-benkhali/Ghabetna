import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
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
    final async = ref.watch(allIncidentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des incidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'Vue liste',
            onPressed: () => context.go('/supervisor/incidents'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allIncidentsProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur:$e')),
        data: (incidents) {
          //only incidents with GPS coords
          final mapped = incidents
              .where((i) => i.latitude != null && i.longitude != null)
              .toList();
          //default center to Tunisia
          final center = mapped.isEmpty
              ? const LatLng(33.8869, 9.5375)
              : LatLng(
                  mapped.map((i) => i.latitude!).reduce((a, b) => a + b) /
                      mapped.length,
                  mapped.map((i) => i.longitude!).reduce((a, b) => a + b) /
                      mapped.length,
                );
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
                    '${mapped.length} incident${mapped.length != 1 ? "s" : ""} géolocalisé${mapped.length != 1 ? "s" : ""}',
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
          const Text(
            'Légende',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 6),
          _LegendItem(color: AppColors.warning, label: 'En attente'),
          _LegendItem(color: AppColors.info, label: 'En cours'),
          _LegendItem(color: AppColors.success, label: 'Résolu'),
          _LegendItem(color: AppColors.danger, label: 'Rejeté'),
          const SizedBox(height: 4),
          const _CriticalLegendItem(),
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
          const Text('Critique', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
