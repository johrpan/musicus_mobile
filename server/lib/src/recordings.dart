import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_database/musicus_database.dart';

import 'auth.dart';

class RecordingsController extends ResourceController {
  final Database db;

  RecordingsController(this.db);

  @Operation.get('id')
  Future<Response> getRecording(@Bind.path('id') int id) async {
    final recording = await db.getRecording(id);
    if (recording != null) {
      return Response.ok(recording);
    } else {
      return Response.notFound();
    }
  }

  @Operation.put('id')
  Future<Response> putRecording(
      @Bind.path('id') int id, @Bind.body() Map<String, dynamic> json) async {
    if (await db.recordingById(id).getSingle() != null) {
      if (!request.mayEdit) {
        return Response.forbidden();
      }
    } else {
      if (!request.mayUpload) {
        return Response.forbidden();
      }
    }
    
    final recordingInfo = RecordingInfo.fromJson(json);
    await db.updateRecording(recordingInfo);
    
    return Response.ok(null);
  }

  @Operation.delete('id')
  Future<Response> deleteRecording(@Bind.path('id') int id) async {
    if (!request.mayDelete) {
      return Response.forbidden();
    }
    
    await db.deleteRecording(id);
    return Response.ok(null);
  }
}
