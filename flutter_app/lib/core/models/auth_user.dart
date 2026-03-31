import 'dart:convert';
import 'package:flutter/foundation.dart';


@immutable
class AuthUser {
    final int id;
    final String email;
    final String fullName;
    final int roleId;
    final String roleName;
    final List<String> permissions;
    final int? serviceId;

    const AuthUser({
        required this.id,
        required this.email,
        required this.fullName,
        required this.roleId,
        required this.roleName,
        required this.permissions,
        this.serviceId
    });
    bool hasPermission(String permission)=>permissions.contains(permission);

    bool get isAgent=>roleName=='agent';
    bool get isSupervisor=>roleName=='supervisor';
    bool get isAdmin=>roleName=='admin';

    // parse from JWT access token (base64 decode the payload)
     
    factory AuthUser.fromToken(String accessToken,{
        required String email,
        required String fullName,
        required String roleName,
        int? serviceId
    }){
        final parts=accessToken.split('.');
        if (parts.length!=3) throw const FormatException('Invalid JWT');
        String payload=parts[1]; 
        payload += '=' * (( 4 - payload.length % 4) % 4);
        final decoded=jsonDecode(utf8.decode(base64Url.decode(payload)));
        return AuthUser(id: int.parse(decoded['sub'] as String), 
        email: email, 
        fullName: fullName, 
        roleId: decoded['role_id'] as int, 
        roleName: roleName, 
        permissions: List<String>.from(decoded['permissions']??[]),
        serviceId: serviceId
        );
    }

}
