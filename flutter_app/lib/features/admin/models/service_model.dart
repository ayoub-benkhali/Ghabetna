class ServiceModel {
  final int id;
  final String name;
  final String type;
  final String? description;

  const ServiceModel({
    required this.id, 
    required this.name, 
    required this.type, 
    required this.description
    });

    factory ServiceModel.fromJson(Map<String,dynamic>j)=>ServiceModel(
      id: j['id'] as int, 
      name: j['name'] as String, 
      type: j['type'] as String,
      description: j['description'] as String?,
    );

  
}
