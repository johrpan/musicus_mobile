import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_database/musicus_database.dart';

class EnsemblesController extends ResourceController {
  final Database db;

  EnsemblesController(this.db);

  @Operation.get()
  Future<Response> getEnsembles() async {
    final ensembles = await db.allEnsembles().get();
    return Response.ok(ensembles);
  }

  @Operation.get('id')
  Future<Response> getEnsemble(@Bind.path('id') int id) async {
    final ensemble = await db.ensembleById(id).getSingle();
    if (ensemble != null) {
      return Response.ok(ensemble);
    } else {
      return Response.notFound();
    }
  }

  @Operation.put('id')
  Future<Response> putEnsemble(
      @Bind.path('id') int id, @Bind.body() Map<String, dynamic> json) async {
    final ensemble = Ensemble.fromJson(json).copyWith(
      id: id,
    );

    await db.updateEnsemble(ensemble);

    return Response.ok(null);
  }
}
