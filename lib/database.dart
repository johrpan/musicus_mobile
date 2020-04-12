import 'dart:io';
import 'dart:math';

import 'package:moor/moor.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as pp;

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

class PerformanceModel {
  final Person person;
  final Ensemble ensemble;
  final Instrument role;

  PerformanceModel({
    this.person,
    this.ensemble,
    this.role,
  });
}

@UseMoor(
  include: {
    'database.moor',
  },
)
class Database extends _$Database {
  Database(String fileName)
      : super(LazyDatabase(() async {
          final dir = await pp.getApplicationDocumentsDirectory();
          final file = File(p.join(dir.path, fileName));
          return VmDatabase(file);
        }));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

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

  Future<void> updateRecording(
      Recording recording, List<PerformanceModel> models) async {
    await transaction(() async {
      await (delete(performances)
            ..where((p) => p.recording.equals(recording.id)))
          .go();
      await into(recordings).insert(recording, orReplace: true);
      for (final model in models) {
        await into(performances).insert(Performance(
          recording: recording.id,
          person: model.person?.id,
          ensemble: model.ensemble?.id,
          role: model.role?.id,
        ));
      }
    });
  }
}
