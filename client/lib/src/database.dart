import 'dart:math';

import 'package:moor/moor.dart';
import 'package:musicus_client/musicus_client.dart';

import 'info.dart';

part 'database.g.dart';

final _random = Random(DateTime.now().millisecondsSinceEpoch);

/// Generate a random ID suitable for use as primary key.
int generateId() => _random.nextInt(0xFFFFFFFF);

/// The database for storing all metadata for the music library.
///
/// This also handles synchronization with a Musicus server.
@UseMoor(include: {'database.moor'})
class MusicusClientDatabase extends _$MusicusClientDatabase {
  /// The number of items contained in one result page.
  static const pageSize = 50;

  /// The client to use for synchronization.
  ///
  /// This may be null indicating that everything should be kept local.
  final MusicusClient client;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  MusicusClientDatabase({
    @required QueryExecutor executor,
    this.client,
  }) : super(executor);

  MusicusClientDatabase.connect({
    @required DatabaseConnection connection,
    this.client,
  }) : super.connect(connection);

  /// Upload all changes to the server.
  ///
  /// If [update] is true, this will also update existing items with new data
  /// from the server.
  Future<void> sync([bool update = false]) async {
    if (update) {
      for (final person in await oldSyncPersons().get()) {
        await updatePerson(await client.getPerson(person.id));
      }
      for (final instrument in await oldSyncInstruments().get()) {
        await updateInstrument(await client.getInstrument(instrument.id));
      }
      for (final work in await oldSyncWorks().get()) {
        final workInfo = await client.getWork(work.id);
        await updateWork(workInfo);
      }
      for (final ensemble in await oldSyncEnsembles().get()) {
        await updateEnsemble(await client.getEnsemble(ensemble.id));
      }
      for (final recording in await oldSyncRecordings().get()) {
        final recordingInfo = await client.getRecording(recording.id);
        await updateRecording(recordingInfo);
      }
    }

    for (final person in await newSyncPersons().get()) {
      await client.putPerson(person);
    }
    for (final instrument in await newSyncInstruments().get()) {
      await client.putInstrument(instrument);
    }
    for (final work in await newSyncWorks().get()) {
      final workInfo = await getWorkInfo(work);
      await client.putWork(workInfo);
    }
    for (final ensemble in await newSyncEnsembles().get()) {
      await client.putEnsemble(ensemble);
    }
    for (final recording in await newSyncRecordings().get()) {
      final recordingInfo = await getRecordingInfo(recording);
      await client.putRecording(recordingInfo);
    }
  }

  /// Get all available persons.
  ///
  /// This will return a list of [pageSize] persons. You can get another page
  /// using the [page] parameter. If a non empty [search] string is provided,
  /// the persons will get filtered based on that string.
  Future<List<Person>> getPersons([int page, String search]) async {
    final offset = page != null ? page * pageSize : 0;
    List<Person> result;

    if (search == null || search.isEmpty) {
      result = await allPersons(pageSize, offset).get();
    } else {
      result = await searchPersons('$search%', pageSize, offset).get();
    }

    return result;
  }

  /// Add [person] or replace an existing person with the same ID.
  Future<void> updatePerson(Person person) async {
    await into(persons).insert(
      person,
      mode: InsertMode.insertOrReplace,
    );

    if (person.sync) {
      await sync();
    }
  }

  /// Delete the person by [id].
  ///
  /// If [sync] is true, the person will be deleted from the server too. If
  /// that fails, a MusicusNotAuthorizedException or MusicusNotLoggedInException
  /// willl be thrown and the person will NOT be deleted.
  Future<void> deletePerson(int id, [bool sync = false]) async {
    if (sync) {
      await client.deletePerson(id);
    }

    await (delete(persons)..where((p) => p.id.equals(id))).go();
  }

  /// Get all available instruments.
  ///
  /// This will return a list of [pageSize] instruments. You can get another
  /// page using the [page] parameter. If a non empty [search] string is
  /// provided, the instruments will get filtered based on that string.
  Future<List<Instrument>> getInstruments([int page, String search]) async {
    final offset = page != null ? page * pageSize : 0;
    List<Instrument> result;

    if (search == null || search.isEmpty) {
      result = await allInstruments(pageSize, offset).get();
    } else {
      result = await searchInstruments('$search%', pageSize, offset).get();
    }

    return result;
  }

  /// Add [instrument] or replace an existing one with the same ID.
  Future<void> updateInstrument(Instrument instrument) async {
    await into(instruments).insert(
      instrument,
      mode: InsertMode.insertOrReplace,
    );

    if (instrument.sync) {
      await sync();
    }
  }

  /// Delete the instrument by [id].
  ///
  /// If [sync] is true, the instrument will be deleted from the server too. If
  /// that fails, a MusicusNotAuthorizedException or MusicusNotLoggedInException
  /// willl be thrown and the instrument will NOT be deleted.
  Future<void> deleteInstrument(int id, [bool sync = false]) async {
    if (sync) {
      await client.deletePerson(id);
    }

    await (delete(instruments)..where((i) => i.id.equals(id))).go();
  }

  /// Retrieve more information on an already queried work.
  Future<WorkInfo> getWorkInfo(Work work) async {
    final id = work.id;

    final composers = await partComposersByWork(id).get();
    composers.insert(0, await personById(work.composer).getSingle());
    final instruments = await instrumentsByWork(id).get();

    final List<PartInfo> parts = [];
    for (final part in await partsByWork(id).get()) {
      parts.add(PartInfo(
        part: part,
        composer: part.composer != null
            ? await personById(part.composer).getSingle()
            : null,
        instruments: await instrumentsByWorkPart(part.id).get(),
      ));
    }

    final List<WorkSection> sections = [];
    for (final section in await sectionsByWork(id).get()) {
      sections.add(section);
    }

    return WorkInfo(
      work: work,
      instruments: instruments,
      composers: composers,
      parts: parts,
      sections: sections,
    );
  }

  /// Get all available information on a work.
  Future<WorkInfo> getWork(int id) async {
    final work = await workById(id).getSingle();
    return await getWorkInfo(work);
  }

  /// Get information on all works written by the person with ID [personId].
  ///
  /// This will return a list of [pageSize] results. You can get another page
  /// using the [page] parameter. If a non empty [search] string is provided,
  /// the works will be filtered using that string.
  Future<List<WorkInfo>> getWorks(int personId,
      [int page, String search]) async {
    final offset = page != null ? page * pageSize : 0;
    List<Work> works;

    if (search == null || search.isEmpty) {
      works = await worksByComposer(personId, pageSize, offset).get();
    } else {
      works =
          await searchWorksByComposer(personId, '$search%', pageSize, offset)
              .get();
    }

    final List<WorkInfo> result = [];
    for (final work in works) {
      result.add(await getWorkInfo(work));
    }

    return result;
  }

  /// Add or replace a work and its associated data.
  ///
  /// This will explicitly update all associated composers and instruments, even
  /// if they have already existed before.
  Future<void> updateWork(WorkInfo workInfo) async {
    await transaction(() async {
      final workId = workInfo.work.id;

      // Delete old work data first. The parts, sections and instrumentations
      // will be deleted automatically due to their foreign key constraints.
      await deleteWork(workId);

      // This will also include the composers of the work's parts.
      for (final person in workInfo.composers) {
        await updatePerson(person);
      }

      await into(works).insert(workInfo.work);

      // At the moment, this will also update all provided instruments, even if
      // they were already there previously.
      for (final instrument in workInfo.instruments) {
        await updateInstrument(instrument);
        await into(instrumentations).insert(Instrumentation(
          work: workId,
          instrument: instrument.id,
        ));
      }

      for (final partInfo in workInfo.parts) {
        final part = partInfo.part;

        await into(workParts).insert(part);

        for (final instrument in workInfo.instruments) {
          await updateInstrument(instrument);
          await into(partInstrumentations).insert(PartInstrumentation(
            workPart: part.id,
            instrument: instrument.id,
          ));
        }
      }

      for (final section in workInfo.sections) {
        await into(workSections).insert(section);
      }
    });

    if (workInfo.work.sync) {
      await sync();
    }
  }

  /// Delete the work by [id].
  ///
  /// If [sync] is true, the work will be deleted from the server too. If
  /// that fails, a MusicusNotAuthorizedException or MusicusNotLoggedInException
  /// willl be thrown and the work will NOT be deleted.
  Future<void> deleteWork(int id, [bool sync = false]) async {
    if (sync) {
      await client.deletePerson(id);
    }

    // The parts and instrumentations will be deleted automatically due to
    // their foreign key constraints.
    await (delete(works)..where((w) => w.id.equals(id))).go();
  }

  /// Get all available ensembles.
  ///
  /// This will return a list of [pageSize] ensembles. You can get another page
  /// using the [page] parameter. If a non empty [search] string is provided,
  /// the ensembles will get filtered based on that string.
  Future<List<Ensemble>> getEnsembles([int page, String search]) async {
    final offset = page != null ? page * pageSize : 0;
    List<Ensemble> result;

    if (search == null || search.isEmpty) {
      result = await allEnsembles(pageSize, offset).get();
    } else {
      result = await searchEnsembles('$search%', pageSize, offset).get();
    }

    return result;
  }

  /// Add [ensemble] or replace an existing one with the same ID.
  Future<void> updateEnsemble(Ensemble ensemble) async {
    await into(ensembles).insert(
      ensemble,
      mode: InsertMode.insertOrReplace,
    );

    if (ensemble.sync) {
      await sync();
    }
  }

  /// Delete the ensemble by [id].
  ///
  /// If [sync] is true, the ensemble will be deleted from the server too. If
  /// that fails, a MusicusNotAuthorizedException or MusicusNotLoggedInException
  /// willl be thrown and the ensemble will NOT be deleted.
  Future<void> deleteEnsemble(int id, [bool sync = false]) async {
    if (sync) {
      await client.deletePerson(id);
    }

    await (delete(ensembles)..where((e) => e.id.equals(id))).go();
  }

  /// Add or replace a recording and its associated data.
  ///
  /// This will explicitly also update all assoicated persons and instruments.
  Future<void> updateRecording(RecordingInfo recordingInfo) async {
    await transaction(() async {
      final recordingId = recordingInfo.recording.id;

      // Delete the old recording first. This will also delete the performances
      // due to their foreign key constraint.
      await deleteRecording(recordingId);

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

    if (recordingInfo.recording.sync) {
      await sync();
    }
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

  /// Delete a recording by [id].
  ///
  /// If [sync] is true, the recording will be deleted from the server too. If
  /// that fails, a MusicusNotAuthorizedException or MusicusNotLoggedInException
  /// willl be thrown and the recording will NOT be deleted.
  Future<void> deleteRecording(int id, [bool sync = false]) async {
    if (sync) {
      await client.deletePerson(id);
    }

    // This will also delete the performances due to their foreign key
    // constraint.
    await (delete(recordings)..where((r) => r.id.equals(id))).go();
  }

  /// Get information on all recordings of the work with ID [workId].
  ///
  /// This will return a list of [pageSize] recordings. You can get the other
  /// pages using the [page] parameter.
  Future<List<RecordingInfo>> getRecordings(int workId, [int page]) async {
    final offset = page != null ? page * pageSize : 0;
    final recordings = await recordingsByWork(workId, pageSize, offset).get();

    final List<RecordingInfo> result = [];
    for (final recording in recordings) {
      result.add(await getRecordingInfo(recording));
    }

    return result;
  }
}
