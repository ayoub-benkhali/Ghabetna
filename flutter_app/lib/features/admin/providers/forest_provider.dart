import 'package:flutter_app/features/admin/data/forest_repository.dart';
import 'package:flutter_app/features/admin/models/forest_model.dart';
import 'package:flutter_app/features/admin/models/parcelle_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final forestRepositoryProvider=Provider((_)=>ForestRepository());

//Forests list
final forestsProvider=FutureProvider<List<ForestModel>>((ref)=>ref.watch(forestRepositoryProvider).getForests());

//Single forest
final forestProvider=FutureProvider.family<ForestModel,int>((ref,id)=>ref.watch(forestRepositoryProvider).getForest(id));

//Parcelles for a forest
final parcellesProvider=FutureProvider.family<List<ParcelleModel>,int>((ref,forestId)=>ref.watch(forestRepositoryProvider).getParcelles(forestId));
