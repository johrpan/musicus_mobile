import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_database/musicus_database.dart';

class PersonsController extends ResourceController {
  final Database db;

  PersonsController(this.db);

  @Operation.get()
  Future<Response> getPersons(
      [@Bind.query('p') int page, @Bind.query('s') String search]) async {
    final persons = await db.getPersons(page, search);
    return Response.ok(persons);
  }

  @Operation.get('id')
  Future<Response> getPerson(@Bind.path('id') int id) async {
    final person = await db.personById(id).getSingle();
    if (person != null) {
      return Response.ok(person);
    } else {
      return Response.notFound();
    }
  }

  @Operation.put('id')
  Future<Response> putPerson(
      @Bind.path('id') int id, @Bind.body() Map<String, dynamic> json) async {
    final person = Person.fromJson(json).copyWith(
      id: id,
    );

    await db.updatePerson(person);

    return Response.ok(null);
  }

  @Operation.delete('id')
  Future<Response> deletePerson(@Bind.path('id') int id) async {
    await db.deletePerson(id);
    return Response.ok(null);
  }
}
