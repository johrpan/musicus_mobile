import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_database/musicus_database.dart';

class WorkRecordingsController extends ResourceController {
  final Database db;

  WorkRecordingsController(this.db);

  @Operation.get('id')
  Future<Response> getRecordings(@Bind.path('id') int id,
      {@Bind.query('p') int page}) async {
    final recordings = await db.getRecordings(id, page);
    return Response.ok(recordings);
  }
}
