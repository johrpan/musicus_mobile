import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_database/musicus_database.dart';

class WorksController extends ResourceController {
  final Database db;

  WorksController(this.db);

  @Operation.get('id')
  Future<Response> getWork(@Bind.path('id') int id) async {
    final work = await db.workById(id).getSingle();
    if (work != null) {
      return Response.ok(work);
    } else {
      return Response.notFound();
    }
  }

  @Operation.put('id')
  Future<Response> putWork(
      @Bind.path('id') int id, @Bind.body() Map<String, dynamic> json) async {
    final data = WorkData.fromJson(json);
    await db.updateWork(data);
    return Response.ok(null);
  }
}