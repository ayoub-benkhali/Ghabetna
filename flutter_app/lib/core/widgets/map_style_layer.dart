// lib/core/widgets/map_style_layer.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

// ── 1. Enum ───────────────────────────────────────────────────────────────────

enum MapStyle { plain, satellite }

// ── 2. Tile layers ────────────────────────────────────────────────────────────

List<Widget> mapTileLayers(MapStyle style) {
  switch (style) {
    case MapStyle.plain:
      return [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ghabetna.app',
          maxZoom: 19,
        ),
      ];

    // Satellite = ESRI imagery + CartoDB labels overlay (hybrid look)
    case MapStyle.satellite:
      return [
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/'
              'World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.ghabetna.app',
          maxZoom: 19,
        ),
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.ghabetna.app',
          maxZoom: 19,
        ),
      ];
  }
}

// ── 3. Attribution widget ─────────────────────────────────────────────────────

Widget mapAttributionWidget(MapStyle style) {
  return RichAttributionWidget(
    attributions: [
      if (style == MapStyle.plain)
        TextSourceAttribution(
          'OpenStreetMap contributors',
          onTap: () =>
              launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
        ),
      if (style == MapStyle.satellite)
        TextSourceAttribution(
          'Esri, Maxar, Earthstar Geographics',
          onTap: () => launchUrl(
            Uri.parse(
              'https://www.esri.com/en-us/legal/terms/data-attributions',
            ),
          ),
        ),
      if (style == MapStyle.satellite)
        TextSourceAttribution(
          '© CartoDB',
          onTap: () => launchUrl(Uri.parse('https://carto.com/attributions')),
        ),
    ],
  );
}

// ── 4. Toggle button ──────────────────────────────────────────────────────────

class MapStyleButton extends StatelessWidget {
  const MapStyleButton({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final MapStyle current;
  final ValueChanged<MapStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: MapStyle.values.map((style) {
          final isSelected = style == current;
          final isFirst = style == MapStyle.plain;
          final isLast = style == MapStyle.satellite;
          return GestureDetector(
            onTap: () => onChanged(style),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2D6A4F)
                    : Colors.transparent,
                borderRadius: BorderRadius.horizontal(
                  left: isFirst ? const Radius.circular(8) : Radius.zero,
                  right: isLast ? const Radius.circular(8) : Radius.zero,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconFor(style),
                    size: 14,
                    color: isSelected ? Colors.white : Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    style == MapStyle.plain
                        ? l.mapStylePlain
                        : l.mapStyleSatellite,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(MapStyle s) => switch (s) {
    MapStyle.plain => Icons.map_outlined,
    MapStyle.satellite => Icons.satellite_alt_outlined,
  };
}
