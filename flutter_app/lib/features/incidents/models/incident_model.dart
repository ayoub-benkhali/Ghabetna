class IncidentModel {
  final int id;
  final String category;
  final String description;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final int? parcelleId;
  final int? forestId;
  final String status;
  final bool isCritical;
  final DateTime createdAt;

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
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) => IncidentModel(
    id: json['id'] as int,
    category: json['category'] as String,
    description: json['description'] as String,
    imageUrl: json['image_url'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    parcelleId: json['parcelle_id'] as int?,
    forestId: json['forest_id'] as int?,
    status: json['status'] as String,
    isCritical: json['is_critical'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
