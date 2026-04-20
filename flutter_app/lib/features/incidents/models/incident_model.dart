import 'package:flutter_app/core/constants/app_constants.dart';

class IncidentModel {
  final int id;
  final String category;
  final String description;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final int? parcelleId;
  final int? forestId;
  final String? supervisorComment;
  final int? supervisorId;
  final String? supervisorName;
  final String? agentName;
  final String status;
  final bool isCritical;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IncidentModel({
    required this.id,
    required this.category,
    required this.description,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.parcelleId,
    this.forestId,
    required this.status,
    required this.isCritical,
    required this.createdAt,
    this.supervisorComment,
    this.supervisorId,
    this.supervisorName,
    this.agentName,
    required this.updatedAt,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['image_url'] as String?;
    final String? resolvedUrl = _resolveImageUrl(rawUrl);

    return IncidentModel(
      id: json['id'] as int,
      category: json['category'] as String,
      description: json['description'] as String,
      imageUrl: resolvedUrl,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      parcelleId: json['parcelle_id'] as int?,
      forestId: json['forest_id'] as int?,
      status: json['status'] as String,
      isCritical: json['is_critical'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      supervisorComment: json['supervisor_comment'] as String?,
      supervisorId: json['supervisor_id'] as int?,
      supervisorName: json['supervisor_name'] as String?,
      agentName: json['agent_name'] as String?,
    );
  }

  /// Converts a server-relative path like "/uploads/foo.jpg" into a full URL
  /// like "http://192.168.1.10:8000/uploads/foo.jpg".
  /// Already-absolute URLs (http/https) are returned unchanged.
  /// Null or empty values return null.
  static String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    // Strip any trailing slash from the base URL then prepend it.
    final base = AppConstants.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    final path = raw.startsWith('/') ? raw : '/$raw';
    return '$base$path';
  }
}
