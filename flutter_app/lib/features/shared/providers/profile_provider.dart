import 'package:dio/dio.dart';
import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/core/providers/user_session_provider.dart';
import 'package:flutter_app/features/admin/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//repository
class ProfileReposiroty {
  final Dio _dio = ApiClient.instance.dio;

  Future<UserModel> fetchMe() async {
    final resp = await _dio.get('/api/users/me');
    return UserModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<UserModel> updateMe({required String fullName}) async {
    final resp = await _dio.put('/api/users/me', data: {'full_name': fullName});
    return UserModel.fromJson(resp.data as Map<String, dynamic>);
  }
}

//providers
final profileRepositoryProvider = Provider<ProfileReposiroty>(
  (_) => ProfileReposiroty(),
);

/// Fetches the current user's full profile from /api/users/me.
final myProfileProvider = FutureProvider<UserModel>((ref) async {
  ref.watch(userSessionProvider);
  return ref.watch(profileRepositoryProvider).fetchMe();
});

class ProfileUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  final ProfileReposiroty _repo;
  final Ref _ref;

  ProfileUpdateNotifier(this._repo, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> updateName(String fullName) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateMe(fullName: fullName);
      if (!mounted) return;
      //Invalidate so the profile card refreshes automatically
      _ref.invalidate(myProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}

final profileUpdateProvider =
    StateNotifierProvider<ProfileUpdateNotifier, AsyncValue<void>>(
      (ref) => ProfileUpdateNotifier(ref.watch(profileRepositoryProvider), ref),
    );
