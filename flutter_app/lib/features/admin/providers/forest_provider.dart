import 'package:flutter_app/features/auth/providers/user_session_provider.dart';
import 'package:flutter_app/features/admin/data/forest_repository.dart';
import 'package:flutter_app/features/admin/models/forest_model.dart';
import 'package:flutter_app/features/admin/models/parcelle_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final forestRepositoryProvider = Provider((_) => ForestRepository());

//Forests list
final forestsProvider = FutureProvider<List<ForestModel>>((ref) {
  ref.watch(userSessionProvider);
  return ref.watch(forestRepositoryProvider).getForests();
});

//Single forest
final forestProvider = FutureProvider.family<ForestModel, int>((ref, id) {
  ref.watch(userSessionProvider);
  return ref.watch(forestRepositoryProvider).getForest(id);
});

//Parcelles for a forest
final parcellesProvider = FutureProvider.family<List<ParcelleModel>, int>((
  ref,
  forestId,
) {
  ref.watch(userSessionProvider);
  return ref.watch(forestRepositoryProvider).getParcelles(forestId);
});

// Fetches a single parcelle by (forestId, parcelleId).
final parcelleProvider = FutureProvider.family<ParcelleModel?, (int, int)>((
  ref,
  ids,
) {
  final (forestId, parcelleId) = ids;
  return ref.watch(forestRepositoryProvider).getParcelle(forestId, parcelleId);
});

// Fetches a single parcelle by parcelleId only (flat lookup — no forestId needed).
final parcelleFlatProvider = FutureProvider.family<ParcelleModel?, int>((
  ref,
  parcelleId,
) {
  ref.watch(userSessionProvider);
  return ref.watch(forestRepositoryProvider).getParcelleFlatById(parcelleId);
});
