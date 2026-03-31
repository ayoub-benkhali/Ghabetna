class ParcelleModel {
  final int id;
  final int forestId;
  final String name;
  final String? description;
  final double? areaHectares;
  final Map<String, dynamic> boundaryGeojson;
  final DateTime createdAt;

  const ParcelleModel({
    required this.id,
    required this.forestId,
    required this.name,
    this.description,
    this.areaHectares,
    required this.boundaryGeojson,
    required this.createdAt,
  });

  factory ParcelleModel.fromJson(Map<String, dynamic> j) => ParcelleModel(
    id: j['id'] as int,
    description: j['description'] as String?,
    areaHectares: (j['area_hectares'] as num?)?.toDouble(),
    forestId: j['forest_id'] as int,
    name: j['name'] as String,
    boundaryGeojson: j['boundary_geojson'] as Map<String, dynamic>,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}
