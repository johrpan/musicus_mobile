import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:musicus_database/musicus_database.dart';
import 'package:musicus_server/src/work_recordings.dart';

import 'compositions.dart';
import 'configuration.dart';
import 'ensembles.dart';
import 'instruments.dart';
import 'persons.dart';
import 'recordings.dart';
import 'works.dart';

class MusicusServer extends ApplicationChannel {
  Database db;

  @override
  Future<void> prepare() async {
    final config = MusicusServerConfiguration(options.configurationFilePath);

    if (config.dbPath != null) {
      db = Database(VmDatabase(File(config.dbPath)));
    } else {
      db = Database(VmDatabase.memory());
    }
  }

  @override
  Controller get entryPoint => Router()
    ..route('/persons/[:id]').link(() => PersonsController(db))
    ..route('/persons/:id/works').link(() => CompositionsController(db))
    ..route('/instruments/[:id]').link(() => InstrumentsController(db))
    ..route('/works/:id').link(() => WorksController(db))
    ..route('/works/:id/recordings').link(() => WorkRecordingsController(db))
    ..route('/ensembles/[:id]').link(() => EnsemblesController(db))
    ..route('/recordings/:id').link(() => RecordingsController(db));
}
