import 'dart:io';

import 'package:flutter_app/core/providers/user_session_provider.dart';
import 'package:flutter_app/features/incidents/data/incident_repository.dart';
import 'package:flutter_app/features/incidents/models/incident_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>(
  (_) => IncidentRepository(),
);

//My incidents list is (auto-refreshable)
final myIncidentsProvider = FutureProvider<List<IncidentModel>>((ref) async {
  ref.watch(userSessionProvider);
  return ref.watch(incidentRepositoryProvider).getMyIncidents();
});

//Report from state
class ReportFormState {
  final bool isLoading;
  final String? error;
  final bool success;

  const ReportFormState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  ReportFormState copyWith({bool? isLoading, String? error, bool? success}) =>
      ReportFormState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        success: success ?? this.success,
      );
}

class ReportFormNotifier extends StateNotifier<ReportFormState> {
  final IncidentRepository _repo;
  final Ref _ref;
  ReportFormNotifier(this._repo, this._ref) : super(const ReportFormState());

  Future<void> submit({
    required String category,
    required String description,
    double? latitude,
    double? longitude,
    int? parcelleId,
    int? forestId,
    bool isCritical = false,
    File? imageFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await _repo.createIncident(
        category: category,
        description: description,
        latitude: latitude,
        longitude: longitude,
        parcelleId: parcelleId,
        forestId: forestId,
        isCritical: isCritical,
        imageFile: imageFile,
      );
      //Invalidate the list so it refreshes automatically
      _ref.invalidate(myIncidentsProvider);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const ReportFormState();
}

final reportFormProvider =
    StateNotifierProvider.autoDispose<ReportFormNotifier, ReportFormState>(
      (ref) => ReportFormNotifier(ref.watch(incidentRepositoryProvider), ref),
    );
