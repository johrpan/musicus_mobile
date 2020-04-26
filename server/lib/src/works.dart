import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_database/musicus_database.dart';

class WorksController extends ResourceController {
  final Database db;

  WorksController(this.db);

  @Operation.get('id')
  Future<Response> getWork(@Bind.path('id') int id) async {
    final work = await db.getWork(id);
    if (work != null) {
      return Response.ok(work);
    } else {
      return Response.notFound();
    }
  }

  @Operation.put('id')
  Future<Response> putWork(
      @Bind.path('id') int id, @Bind.body() Map<String, dynamic> json) async {
    final workInfo = WorkInfo.fromJson(json);
    await db.updateWork(workInfo);

    return Response.ok(null);
  }
}
