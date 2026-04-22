import 'package:flutter_app/features/admin/data/forest_repository.dart';
import 'package:flutter_app/features/admin/models/forest_model.dart';
import 'package:flutter_app/features/admin/models/parcelle_model.dart';
import 'package:flutter_app/features/incidents/models/incident_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeoContext {
  final ForestModel? forest;
  final ParcelleModel? parcelle;
  const GeoContext({this.forest, this.parcelle});
}

final geoContextProvider = FutureProvider.family<GeoContext, IncidentModel>((
  ref,
  incident,
) async {
  if (incident.forestId == null) return const GeoContext();

  final repo = ForestRepository();
  final forest = await repo.getForest(incident.forestId!);
  final parcelle = incident.parcelleId != null
      ? await repo.getParcelle(incident.forestId!, incident.parcelleId!)
      : null;

  return GeoContext(forest: forest, parcelle: parcelle);
});
