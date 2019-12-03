import 'package:moor_flutter/moor_flutter.dart';

part 'database.g.dart';

@UseMoor(
  include: {
    'database.moor',
  },
)
class Database extends _$Database {
  Database(String fileName)
      : super(FlutterQueryExecutor.inDatabaseFolder(path: fileName));

  @override
  int get schemaVersion => 0;

  Future<void> updatePerson(Person person) async {
    await into(persons).insert(person);
  }

  Future<void> updateInstrument(Instrument instrument) async {
    await into(instruments).insert(instrument);
  }

  Future<void> updateWork(Work work, List<int> instrumentIds) async {
    await transaction(() async {
      await into(works).insert(work);

      await (delete(instrumentations)..where((i) => i.work.equals(work.id)))
          .go();

      await into(instrumentations).insertAll(instrumentIds
          .map((id) => Instrumentation(
                work: work.id,
                instrument: id,
              ))
          .toList());
    });
  }
}
