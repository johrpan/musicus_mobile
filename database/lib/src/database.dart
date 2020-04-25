import 'dart:math';

import 'package:moor/moor.dart';

import 'info.dart';

part 'database.g.dart';

final _random = Random(DateTime.now().millisecondsSinceEpoch);
int generateId() => _random.nextInt(0xFFFFFFFF);

class WorkPartData {
  final Work work;
  final List<int> instrumentIds;

  WorkPartData({
    this.work,
    this.instrumentIds,
  });

  factory WorkPartData.fromJson(Map<String, dynamic> json) => WorkPartData(
        work: Work.fromJson(json['work']),
        instrumentIds: List<int>.from(json['instrumentIds']),
      );

  Map<String, dynamic> toJson() => {
        'work': work.toJson(),
        'instrumentIds': instrumentIds,
      };
}

class WorkData {
  final WorkPartData data;
  final List<WorkPartData> partData;

  WorkData({
    this.data,
    this.partData,
  });

  factory WorkData.fromJson(Map<String, dynamic> json) => WorkData(
        data: WorkPartData.fromJson(json['data']),
        partData: json['partData']
            .map<WorkPartData>((j) => WorkPartData.fromJson(j))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'data': data.toJson(),
        'partData': partData.map((d) => d.toJson()).toList(),
      };
}

class RecordingData {
  final Recording recording;
  final List<Performance> performances;

  RecordingData({
    this.recording,
    this.performances,
  });

  factory RecordingData.fromJson(Map<String, dynamic> json) => RecordingData(
        recording: Recording.fromJson(json['recording']),
        performances: json['performances']
            .map<Performance>((j) => Performance.fromJson(j))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'recording': recording.toJson(),
        'performances': performances.map((p) => p.toJson()).toList(),
      };
}

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

  Future<void> updateWork(WorkData data) async {
    await transaction(() async {
      final workId = data.data.work.id;
      await (delete(works)..where((w) => w.id.equals(workId))).go();
      await (delete(works)..where((w) => w.partOf.equals(workId))).go();

      Future<void> insertWork(WorkPartData partData) async {
        await into(works).insert(partData.work);
        await batch((b) => b.insertAll(
            instrumentations,
            partData.instrumentIds
                .map((id) =>
                    Instrumentation(work: partData.work.id, instrument: id))
                .toList()));
      }

      await insertWork(data.data);
      for (final partData in data.partData) {
        await insertWork(partData);
      }
    });
  }

  Future<void> updateEnsemble(Ensemble ensemble) async {
    await into(ensembles).insert(ensemble, orReplace: true);
  }

  Future<void> updateRecording(RecordingData data) async {
    await transaction(() async {
      await (delete(performances)
            ..where((p) => p.recording.equals(data.recording.id)))
          .go();
      await into(recordings).insert(data.recording, orReplace: true);
      for (final performance in data.performances) {
        await into(performances).insert(performance);
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
