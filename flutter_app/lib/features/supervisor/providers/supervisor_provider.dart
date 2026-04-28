import 'dart:async';

import 'package:flutter_app/core/providers/user_session_provider.dart';
import 'package:flutter_app/features/incidents/models/incident_model.dart';
import 'package:flutter_app/features/supervisor/data/supervisor_incident_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns true if the incident should still be visible on the supervisor screen.
/// - "resolved" incidents disappear after 1 hour from their last update.
/// - All other statuses (pending, in_progress, rejected, etc.) disappear after 24 hours from creation.
bool _isIncidentVisible(IncidentModel incident) {
  final now = DateTime.now();

  if (incident.status == 'resolved') {
    final resolvedTime = incident.resolvedAt ?? incident.updatedAt;
    return now.difference(resolvedTime) < const Duration(hours: 1);
  }

  return now.difference(incident.createdAt) < const Duration(hours: 24);
}

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
  ref.watch(userSessionProvider); // resets filter to default on session change
  return const IncidentFilter();
});

final allIncidentsProvider = FutureProvider<List<IncidentModel>>((ref) async {
  final filter = ref.watch(incidentFilterProvider);
  ref.watch(userSessionProvider);

  // Auto-refresh every 5 minutes so time-based hiding kicks in without manual pull.
  final timer = Timer(const Duration(minutes: 5), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final incidents = await ref
      .watch(supervisorRepoProvider)
      .getAllIncidents(status: filter.status, category: filter.category);

  //return incidents.where(_isIncidentVisible).toList();
  return incidents;
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
    .family<IncidentModel, int>((ref, id) async {
      final incident = await ref.watch(supervisorRepoProvider).getById(id);

      // The geo-enrichment worker runs asynchronously on the backend. If the
      // incident is still pending, schedule a re-fetch so the detail screen
      // updates automatically once enrichment completes — without the user
      // having to navigate away and back.
      if (incident.geoEnrichmentStatus == 'pending') {
        final timer = Timer(const Duration(seconds: 3), () {
          ref.invalidateSelf();
        });
        ref.onDispose(timer.cancel);
      }

      return incident;
    });
