import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_database/musicus_database.dart';

class RecordingsController extends ResourceController {
  final Database db;

  RecordingsController(this.db);

  @Operation.get('id')
  Future<Response> getRecording(@Bind.path('id') int id) async {
    final recording = await db.recordingById(id).getSingle();
    if (recording != null) {
      return Response.ok(recording);
    } else {
      return Response.notFound();
    }
  }

  @Operation.put('id')
  Future<Response> putRecording(
      @Bind.path('id') int id, @Bind.body() Map<String, dynamic> json) async {
    final data = RecordingData.fromJson(json);
    await db.updateRecording(data);
    return Response.ok(null);
  }
}
