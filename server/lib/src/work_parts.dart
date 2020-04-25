import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_database/musicus_database.dart';

class WorkPartsController extends ResourceController {
  final Database db;

  WorkPartsController(this.db);

  @Operation.get('id')
  Future<Response> getParts(@Bind.path('id') int id) async {
    final parts = await db.workParts(id).get();
    return Response.ok(parts);
  }
}
