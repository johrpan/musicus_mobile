import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:musicus_database/musicus_database.dart';

import 'auth.dart';
import 'compositions.dart';
import 'configuration.dart';
import 'database.dart';
import 'ensembles.dart';
import 'instruments.dart';
import 'persons.dart';
import 'recordings.dart';
import 'works.dart';
import 'work_recordings.dart';

class MusicusServer extends ApplicationChannel {
  Database db;
  ServerDatabase serverDb;
  String secret;

  @override
  Future<void> prepare() async {
    final config = MusicusServerConfiguration(options.configurationFilePath);

    if (config.dbPath != null) {
      db = Database(VmDatabase(File(config.dbPath)));
    } else {
      db = Database(VmDatabase.memory());
    }

    if (config.serverDbPath != null) {
      serverDb = ServerDatabase(VmDatabase(File(config.serverDbPath)));
    } else {
      serverDb = ServerDatabase(VmDatabase.memory());
    }

    secret = config.secret;
  }

  @override
  Controller get entryPoint => Router()
    ..route('/account/register').link(() => RegisterController(serverDb))
    ..route('/account/details')
        .link(() => AuthorizationController(serverDb, secret))
        .link(() => AccountDetailsController(serverDb))
    ..route('/account/delete').link(() => AccountDeleteController(serverDb))
    ..route('/account/login').link(() => LoginController(serverDb, secret))
    ..route('/persons/[:id]')
        .link(() => AuthorizationController(serverDb, secret))
        .link(() => PersonsController(db))
    ..route('/persons/:id/works').link(() => CompositionsController(db))
    ..route('/instruments/[:id]')
        .link(() => AuthorizationController(serverDb, secret))
        .link(() => InstrumentsController(db))
    ..route('/works/:id')
        .link(() => AuthorizationController(serverDb, secret))
        .link(() => WorksController(db))
    ..route('/works/:id/recordings').link(() => WorkRecordingsController(db))
    ..route('/ensembles/[:id]')
        .link(() => AuthorizationController(serverDb, secret))
        .link(() => EnsemblesController(db))
    ..route('/recordings/:id')
        .link(() => AuthorizationController(serverDb, secret))
        .link(() => RecordingsController(db));
}
