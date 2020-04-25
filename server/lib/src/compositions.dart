import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_database/musicus_database.dart';

class CompositionsController extends ResourceController {
  final Database db;

  CompositionsController(this.db);

  @Operation.get('id')
  Future<Response> getWorks(@Bind.path('id') int id) async {
    final works = db.worksByComposer(id).get();
    return Response.ok(works);
  }
}
