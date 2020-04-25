import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_database/musicus_database.dart';

class PerformancesController extends ResourceController {
  final Database db;

  PerformancesController(this.db);

  @Operation.get('id')
  Future<Response> getPerformances(@Bind.path('id') int id) async {
    final performances = await db.performancesByRecording(id).get();
    return Response.ok(performances);
  }
}
