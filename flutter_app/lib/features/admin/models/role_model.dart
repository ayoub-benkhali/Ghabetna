class RoleModel {
  final int id;
  final String name;
  final String? description;
  final List<String> permissions;

  const RoleModel({
    required this.id, 
    required this.name, 
    this.description, 
    required this.permissions
    });

    factory RoleModel.fromJson(Map<String,dynamic>j)=>RoleModel(
      id: j['id'] as int, 
      name: j['name'] as String, 
      description: j['description'] as String?,
      permissions: List<String>.from(j['permissions'] as List)
    );
}
