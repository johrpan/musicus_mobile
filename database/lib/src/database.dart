import 'dart:math';

import 'package:moor/moor.dart';

import 'info.dart';

part 'database.g.dart';

final _random = Random(DateTime.now().millisecondsSinceEpoch);
int generateId() => _random.nextInt(0xFFFFFFFF);

@UseMoor(
  include: {
    'database.moor',
  },
)
class Database extends _$Database {
  Database(QueryExecutor queryExecutor) : super(queryExecutor);

  Database.connect(DatabaseConnection connection) : super.connect(connection);

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

  /// Retrieve more information on an already queried work.
  Future<WorkInfo> getWorkInfo(Work work) async {
    final id = work.id;

    final composers = await composersByWork(id).get();
    final instruments = await instrumentsByWork(id).get();

    final List<PartInfo> parts = [];
    for (final part in await workParts(id).get()) {
      parts.add(PartInfo(
        work: part,
        composer: part.composer != null
            ? await personById(part.composer).getSingle()
            : null,
        instruments: await instrumentsByWork(id).get(),
      ));
    }

    return WorkInfo(
      work: work,
      instruments: instruments,
      composers: composers,
      parts: parts,
    );
  }

  /// Get all available information on a work.
  Future<WorkInfo> getWork(int id) async {
    final work = await workById(id).getSingle();
    return await getWorkInfo(work);
  }

  /// Get information on all works written by the person with ID [personId].
  Future<List<WorkInfo>> getWorks(int personId) async {
    final works = await worksByComposer(personId).get();

    final List<WorkInfo> result = [];
    for (final work in works) {
      result.add(await getWorkInfo(work));
    }

    return result;
  }

  /// Update a work and its associated data.
  ///
  /// This will explicitly update all associated composers and instruments, even
  /// if they have already existed before.
  Future<void> updateWork(WorkInfo workInfo) async {
    await transaction(() async {
      final workId = workInfo.work.id;

      // Delete old work data first. The parts and instrumentations will be
      // deleted automatically due to their foreign key constraints.
      await (delete(works)..where((w) => w.id.equals(workId))).go();

      /// Insert instrumentations for a work.
      ///
      /// At the moment, this will also update all provided instruments, even
      /// if they were already there previously.
      Future<void> insertInstrumentations(
          int workId, List<Instrument> instruments) async {
        for (final instrument in instruments) {
          await updateInstrument(instrument);
          await into(instrumentations).insert(Instrumentation(
            work: workId,
            instrument: instrument.id,
          ));
        }
      }

      // This will also include the composers of the work's parts.
      for (final person in workInfo.composers) {
        await updatePerson(person);
      }

      await into(works).insert(workInfo.work);
      await insertInstrumentations(workId, workInfo.instruments);

      for (final partInfo in workInfo.parts) {
        await into(works).insert(partInfo.work);
        await insertInstrumentations(partInfo.work.id, partInfo.instruments);
      }
    });
  }

  Future<void> updateEnsemble(Ensemble ensemble) async {
    await into(ensembles).insert(ensemble, orReplace: true);
  }

  /// Update a recording and its associated data.
  ///
  /// This will explicitly also update all assoicated persons and instruments.
  Future<void> updateRecording(RecordingInfo recordingInfo) async {
    await transaction(() async {
      final recordingId = recordingInfo.recording.id;

      // Delete the old recording first. This will also delete the performances
      // due to their foreign key constraint.
      await (delete(recordings)..where((r) => r.id.equals(recordingId))).go();

      await into(recordings).insert(recordingInfo.recording);

      for (final performance in recordingInfo.performances) {
        if (performance.person != null) {
          await updatePerson(performance.person);
        }

        if (performance.ensemble != null) {
          await updateEnsemble(performance.ensemble);
        }

        if (performance.role != null) {
          await updateInstrument(performance.role);
        }

        await into(performances).insert(Performance(
          recording: recordingId,
          person: performance.person?.id,
          ensemble: performance.ensemble?.id,
          role: performance.role?.id,
        ));
      }
    });
  }

  /// Retreive more information on an already queried recording.
  Future<RecordingInfo> getRecordingInfo(Recording recording) async {
    final id = recording.id;

    final List<PerformanceInfo> performances = [];
    for (final performance in await performancesByRecording(id).get()) {
      performances.add(PerformanceInfo(
        person: performance.person != null
            ? await personById(performance.person).getSingle()
            : null,
        ensemble: performance.ensemble != null
            ? await ensembleById(performance.ensemble).getSingle()
            : null,
        role: performance.role != null
            ? await instrumentById(performance.role).getSingle()
            : null,
      ));
    }

    return RecordingInfo(
      recording: recording,
      performances: performances,
    );
  }

  /// Get all available information on a recording.
  Future<RecordingInfo> getRecording(int id) async {
    final recording = await recordingById(id).getSingle();
    return await getRecordingInfo(recording);
  }

  /// Get information on all recordings of the work with ID [workId].
  Future<List<RecordingInfo>> getRecordings(int workId) async {
    final recordings = await recordingsByWork(workId).get();

    final List<RecordingInfo> result = [];
    for (final recording in recordings) {
      result.add(await getRecordingInfo(recording));
    }

    return result;
  }
}
