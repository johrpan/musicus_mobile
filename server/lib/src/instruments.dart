import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_database/musicus_database.dart';

class InstrumentsController extends ResourceController {
  final Database db;

  InstrumentsController(this.db);

  @Operation.get()
  Future<Response> getInstruments() async {
    final instruments = await db.allInstruments().get();
    return Response.ok(instruments);
  }

  @Operation.get('id')
  Future<Response> getInstrument(@Bind.path('id') int id) async {
    final instrument = await db.instrumentById(id).getSingle();
    if (instrument != null) {
      return Response.ok(instrument);
    } else {
      return Response.notFound();
    }
  }

  @Operation.put('id')
  Future<Response> putInstrument(
      @Bind.path('id') int id, @Bind.body() Map<String, dynamic> json) async {
    final instrument = Instrument.fromJson(json).copyWith(
      id: id,
    );

    await db.updateInstrument(instrument);

    return Response.ok(null);
  }

  @Operation.delete('id')
  Future<Response> deleteInstrument(@Bind.path('id') int id) async {
    await db.deleteInstrument(id);
    return Response.ok(null);
  }
}
