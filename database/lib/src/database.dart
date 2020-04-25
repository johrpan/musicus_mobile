import 'dart:math';

import 'package:moor/moor.dart';

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
}
