import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_database/musicus_database.dart';

import 'auth.dart';

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
    if (await db.workById(id).getSingle() != null) {
      if (!request.mayEdit) {
        return Response.forbidden();
      }
    } else {
      if (!request.mayUpload) {
        return Response.forbidden();
      }
    }
    
    final workInfo = WorkInfo.fromJson(json);
    await db.updateWork(workInfo);

    return Response.ok(null);
  }

  @Operation.delete('id')
  Future<Response> deleteWork(@Bind.path('id') int id) async {
    if (!request.mayDelete) {
      return Response.forbidden();
    }

    await db.deleteWork(id);
    return Response.ok(null);
  }
}
