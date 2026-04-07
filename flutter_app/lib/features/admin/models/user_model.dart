class UserModel {
  final int id;
  final String email;
  final String fullName;
  final int roleId;
  final String roleName;
  final int? serviceId;
  final int? parcelleId;
  final int? forestId;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id, 
    required this.email, 
    required this.fullName, 
    required this.roleId,
    required this.roleName, 
    required this.serviceId, 
    this.parcelleId,
    this.forestId,
    required this.isActive, 
    required this.createdAt
    });
  factory UserModel.fromJson(Map<String,dynamic>j)=>UserModel(
  id: j['id'] as int, 
  email: j['email'] as String,
  fullName: j['full_name'] as String,
  roleId: j['role_id'] as int,
  roleName: (j['role'] as Map<String,dynamic>)['name'] as String,
  serviceId: j['service_id'] as int?,
  parcelleId: j['parcelle_id'] as int?,
  forestId: j['forest_id'] as int?,
  isActive: j['is_active'] as bool,
  createdAt: DateTime.parse(j['created_at']as String)
  );


}
