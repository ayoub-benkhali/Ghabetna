import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/features/agent/models/coord_source.dart';
import 'package:flutter_app/features/incidents/providers/incident_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:native_exif/native_exif.dart';

List<(String, String, IconData)> _buildCategories(BuildContext context) {
  final l = context.l10n;
  return [
    ('feu', l.typeIncendie, Icons.local_fire_department),
    ('coupe_illegale', l.typeCoupeIllegale, Icons.carpenter_outlined),
    ('refuge_suspect', l.typeRefugeSuspect, Icons.warning_amber_outlined),
    ('trafic', l.typeTrafic, Icons.dangerous_outlined),
    ('dechet', l.typeDechet, Icons.delete_outline),
    ('maladie', l.typeMaladie, Icons.coronavirus_outlined),
    ('autre', l.typeAutre, Icons.help_outline),
  ];
}

class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key});
  @override
  ConsumerState<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  CoordSource _coordSource = CoordSource.none;
  final _descController = TextEditingController();
  String _selectedCategory = 'autre';
  File? _imageFile;
  double? _lat, _lng;
  bool _locating = false;
  bool _isCritical = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.locationDisabled)),
          );
        }
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (_coordSource != CoordSource.exif) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _coordSource = CoordSource.gps;
        });
      }
    } catch (e) {
      debugPrint('Location error: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() => _imageFile = file);

    final extracted = await _extractGpsFromExif(file.path);
    if (extracted != null) {
      setState(() {
        _lat = extracted.$1;
        _lng = extracted.$2;
        _coordSource = CoordSource.exif;
      });
    }
  }

  Future<(double, double)?> _extractGpsFromExif(String imagePath) async {
    try {
      final exif = await Exif.fromPath(imagePath);
      final lat = await exif.getLatLong();
      await exif.close();

      if (lat == null) return null;
      if (!lat.latitude.isFinite || !lat.longitude.isFinite) return null;
      if (lat.latitude < -90 || lat.latitude > 90) return null;
      if (lat.longitude < -180 || lat.longitude > 180) return null;

      return (lat.latitude, lat.longitude);
    } catch (_) {
      return null;
    }
  }

  void _submit() {
    final l = context.l10n;
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.addDescription)));
      return;
    }
    ref
        .read(reportFormProvider.notifier)
        .submit(
          category: _selectedCategory,
          description: _descController.text.trim(),
          latitude: _lat,
          longitude: _lng,
          isCritical: _isCritical,
          imageFile: _imageFile,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final formState = ref.watch(reportFormProvider);
    final categories = _buildCategories(context);

    ref.listen(reportFormProvider, (_, next) {
      if (next.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.incidentReported)));
        Navigator.of(context).pop();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l.reportIncident)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // GPS status chip
            Row(
              children: [
                Icon(
                  _locating
                      ? Icons.gps_not_fixed
                      : (_coordSource == CoordSource.exif
                            ? Icons.photo_camera_outlined
                            : _coordSource == CoordSource.gps
                            ? Icons.gps_fixed
                            : Icons.gps_off),
                  size: 16,
                  color: _coordSource != CoordSource.none
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  _locating
                      ? l.locating
                      : (_coordSource == CoordSource.exif
                            ? '${l.photo}: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                            : _coordSource == CoordSource.gps
                            ? 'GPS: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                            : l.locationUnavailable),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final (value, label, icon) = categories[i];
                final selected = _selectedCategory == value;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = value),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                      color: selected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.08)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Is critical
                    SwitchListTile(
                      value: _isCritical,
                      onChanged: (v) => setState(() => _isCritical = v),
                      title: Text(l.criticalIncident),
                      subtitle: Text(l.criticalIncidentHint),
                      activeThumbColor: AppColors.danger,
                      secondary: Icon(
                        Icons.warning_amber_rounded,
                        color: _isCritical ? AppColors.danger : Colors.grey,
                      ),
                    ),
                    const Divider(height: 24),

                    // Description
                    TextField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: l.description,
                        hintText: l.describeIncident,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 6,
                    ),
                    const SizedBox(height: 16),

                    // Image picker
                    if (_imageFile != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _imageFile!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: Text(l.camera),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: Text(l.gallery),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: formState.isLoading ? null : _submit,
                child: formState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.sendReport),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
