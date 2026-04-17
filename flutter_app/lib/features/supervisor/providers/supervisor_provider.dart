import 'package:flutter_app/core/providers/user_session_provider.dart';
import 'package:flutter_app/features/incidents/models/incident_model.dart';
import 'package:flutter_app/features/supervisor/data/supervisor_incident_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final supervisorRepoProvider = Provider((_) => SupervisorIncidentRepository());

//Filter state
class IncidentFilter {
  final String? status;
  final String? category;
  const IncidentFilter({this.status, this.category});
  IncidentFilter copyWith({
    String? status,
    String? category,
    bool clearStatus = false,
    bool clearCategory = false,
  }) => IncidentFilter(
    status: clearStatus ? null : status ?? this.status,
    category: clearCategory ? null : category ?? this.category,
  );
}

final incidentFilterProvider = StateProvider<IncidentFilter>((ref) {
  ref.watch(
    userSessionProvider,
  ); // ADD — resets filter to default on session change
  return const IncidentFilter();
});

final allIncidentsProvider = FutureProvider<List<IncidentModel>>((ref) {
  final filter = ref.watch(incidentFilterProvider);
  ref.watch(userSessionProvider);
  return ref
      .watch(supervisorRepoProvider)
      .getAllIncidents(status: filter.status, category: filter.category);
});

// Update status notifier
class StatusUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  final SupervisorIncidentRepository _repo;
  final Ref _ref;
  StatusUpdateNotifier(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> update(int id, String status, {String? comment}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.updateStatus(id, status, comment: comment);
      _ref.invalidate(allIncidentsProvider);
      _ref.invalidate(singleIncidentProvider(id));
    });
  }
}

final statusUpdateProvider =
    StateNotifierProvider.autoDispose<StatusUpdateNotifier, AsyncValue<void>>(
      (ref) => StatusUpdateNotifier(ref.watch(supervisorRepoProvider), ref),
    );

final singleIncidentProvider = FutureProvider.autoDispose
    .family<IncidentModel, int>((ref, id) {
      return ref.watch(supervisorRepoProvider).getById(id);
    });
