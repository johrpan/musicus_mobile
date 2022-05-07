import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:musicus_database/musicus_database.dart';

/// Manager for all available tracks and their representation on disk.
class MusicusLibrary {
  /// Starts the database isolate.
  ///
  /// It will create a database connection for [request.path] and will send the
  /// drift send port through [request.sendPort].
  static void _dbIsolateEntrypoint(_IsolateStartRequest request) {
    final executor = NativeDatabase(File(request.path));


    final driftIsolate =
        DriftIsolate.inCurrent(() => DatabaseConnection.fromExecutor(executor));

    request.sendPort.send(driftIsolate.connectPort);
  }

  /// String representing the music library base path.
  final String basePath;

  /// The actual music library database.
  MusicusClientDatabase db;

  MusicusLibrary(this.basePath);

  /// Load all available tracks.
  ///
  /// This recursively searches through the whole music library, reads the
  /// content of all files called musicus.json and stores all track information
  /// that it found.
  Future<void> load() async {
    SendPort driftPort = IsolateNameServer.lookupPortByName('drift');

    if (driftPort == null) {
      final receivePort = ReceivePort();

      await Isolate.spawn(
        _dbIsolateEntrypoint,
        _IsolateStartRequest(
            receivePort.sendPort, p.join(basePath, 'musicus.db')),
      );

      driftPort = await receivePort.first;
      IsolateNameServer.registerPortWithName(driftPort, 'drift');
    }

    final driftIsolate = DriftIsolate.fromConnectPort(driftPort);
    db = MusicusClientDatabase.connect(
      connection: await driftIsolate.connect(),
    );
  }
}

/// Bundles arguments for the database isolate.
class _IsolateStartRequest {
  final SendPort sendPort;
  final String path;

  _IsolateStartRequest(this.sendPort, this.path);
}
