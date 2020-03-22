import 'dart:math';

import 'package:moor_flutter/moor_flutter.dart';

part 'database.g.dart';

final _random = Random(DateTime.now().millisecondsSinceEpoch);
int generateId() => _random.nextInt(0xFFFFFFFF);

class WorkModel {
  final Work work;
  final List<int> instrumentIds;

  WorkModel({
    @required this.work,
    @required this.instrumentIds,
  });
}

@UseMoor(
  include: {
    'database.moor',
  },
)
class Database extends _$Database {
  Database(String fileName)
      : super(FlutterQueryExecutor.inDatabaseFolder(path: fileName));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      });

  // TODO: Remove this once https://github.com/simolus3/moor/issues/453 is fixed.
  Selectable<Work> worksByComposer(int id) {
    return customSelectQuery(
        'SELECT DISTINCT A.* FROM works A, works B ON A.id = B.part_of WHERE A.composer = :id OR B.composer = :id',
        variables: [Variable.withInt(id)],
        readsFrom: {works}).map(_rowToWork);
  }

  Future<void> updatePerson(Person person) async {
    await into(persons).insert(person, orReplace: true);
  }

  Future<void> updateInstrument(Instrument instrument) async {
    await into(instruments).insert(instrument, orReplace: true);
  }

  Future<void> updateWork(WorkModel model, List<WorkModel> parts) async {
    await transaction(() async {
      final workId = model.work.id;
      await (delete(works)..where((w) => w.id.equals(workId))).go();
      await (delete(works)..where((w) => w.partOf.equals(workId))).go();

      Future<void> insertWork(WorkModel model) async {
        await into(works).insert(model.work);
        await batch((b) => b.insertAll(
            instrumentations,
            model.instrumentIds
                .map((id) =>
                    Instrumentation(work: model.work.id, instrument: id))
                .toList()));
      }

      await insertWork(model);
      for (final part in parts) {
        await insertWork(part);
      }
    });
  }

  Future<void> updateEnsemble(Ensemble ensemble) async {
    await into(ensembles).insert(ensemble, orReplace: true);
  }

  Future<void> updateRole(Role role) async {
    await into(roles).insert(role, orReplace: true);
  }

  Future<void> updateRecording(
      Recording recording, List<Performance> perfs) async {
    await transaction(() async {
      await (delete(performances)..where((p) => p.recording.equals(recording.id))).go();
      await into(recordings).insert(recording, orReplace: true);
      for (final perf in perfs) {
        await into(performances).insert(perf);
      }
    });
  }
}
