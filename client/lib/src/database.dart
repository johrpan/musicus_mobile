import 'dart:math';

import 'package:drift/drift.dart';

import 'info.dart';

part 'database.g.dart';

final _random = Random(DateTime.now().millisecondsSinceEpoch);

/// Generate a random ID suitable for use as primary key.
int generateId() => _random.nextInt(0xFFFFFFFF);

/// The database for storing all metadata for the music library.
///
/// This also handles synchronization with a Musicus server.
@DriftDatabase(include: {'database.drift'})
class MusicusClientDatabase extends _$MusicusClientDatabase {
  /// The number of items contained in one result page.
  static const pageSize = 50;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  MusicusClientDatabase({
    @required QueryExecutor executor,
  }) : super(executor);

  MusicusClientDatabase.connect({
    @required DatabaseConnection connection,
  }) : super.connect(connection);


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
