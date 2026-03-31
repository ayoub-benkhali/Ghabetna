import 'package:flutter_app/features/admin/data/role_repository.dart';
import 'package:flutter_app/features/admin/data/service_repository.dart';
import 'package:flutter_app/features/admin/data/user_repository.dart';
import 'package:flutter_app/features/admin/models/role_model.dart';
import 'package:flutter_app/features/admin/models/service_model.dart';
import 'package:flutter_app/features/admin/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final userRepositoryProvider=Provider((_)=>UserRepository());
final roleRepositoryProvider=Provider((_)=>RoleRepository());
final serviceRepositoryProvider=Provider((_)=>ServiceRepository());

final usersProvider=FutureProvider<List<UserModel>>((ref)=>ref.watch(userRepositoryProvider).getUsers());
final rolesProvider=FutureProvider<List<RoleModel>>((ref)=>ref.watch(roleRepositoryProvider).getRoles());
final servicesProvider=FutureProvider<List<ServiceModel>>((ref)=>ref.watch(serviceRepositoryProvider).getServices());
