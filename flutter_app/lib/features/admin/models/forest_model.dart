class ForestModel {
  final int id;
  final String name;
  final String? region;
  final String? description;
  final double? areaHectares;
  final double? centerLat;
  final double? centerLng;
  final Map<String,dynamic>? boundaryGeojson;
  final int parcelleCount;
  final DateTime createdAt;

  const ForestModel({
    required this.id, 
    required this.name, 
    this.region, 
    this.description, 
    this.areaHectares, 
    this.centerLat, 
    this.centerLng, 
    this.boundaryGeojson, 
    this.parcelleCount=0,
    required this.createdAt
  });
  
  factory ForestModel.fromJson(Map<String,dynamic> j)=>ForestModel(
    id: j['id'] as int, 
    name: j['name'] as String, 
    region: j['region'] as String?,
    description: j['description'] as String?,
    areaHectares: (j['area_hectares'] as num?)?.toDouble(),
    centerLat: (j['center_lat'] as num?)?.toDouble(),
    centerLng: (j['center_lng'] as num?)?.toDouble(),
    boundaryGeojson: j['boundary_geojson'] as Map<String,dynamic>?,
    parcelleCount: (j['parcelle_count'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(j['created_at']as String)
    );
}
