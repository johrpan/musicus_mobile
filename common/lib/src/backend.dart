import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:musicus_client/musicus_client.dart';
import 'package:musicus_database/musicus_database.dart';

import 'library.dart';
import 'platform.dart';
import 'playback.dart';
import 'settings.dart';

/// Current status of the backend.
enum MusicusBackendStatus {
  /// The backend is loading.
  ///
  /// It is not allowed to call any methods on the backend in this state.
  loading,

  /// Required settings are missing.
  ///
  /// Currently this only includes the music library path. It is not allowed to
  /// call any methods on the backend in this state.
  setup,

  /// The backend is ready to be used.
  ///
  /// This is the only state, in which it is allowed to call methods on the
  /// backend.
  ready,
}

/// Meta widget holding all backend ressources for Musicus.
///
/// This widget is intended to sit near the top of the widget tree. Widgets
/// below it can get the current backend state using the static [of] method.
/// The backend is intended to be used exactly once and live until the UI is
/// exited. Because of that, consuming widgets don't need to care about a
/// change of the backend state object.
///
/// The backend maintains a Musicus database within a Moor isolate. The connect
/// port will be registered as 'moor' in the [IsolateNameServer].
class MusicusBackend extends StatefulWidget {
  /// Path to the database file.
  final String dbPath;

  /// An object to persist the settings.
  final MusicusSettingsStorage settingsStorage;

  /// An object handling playback.
  final MusicusPlayback playback;

  /// An object handling platform dependent functionality.
  final MusicusPlatform platform;

  /// The first child below the backend widget.
  ///
  /// This widget should keep track of the current backend status and block
  /// other widgets from accessing the backend until its status is set to
  /// [MusicusBackendStatus.ready].
  final Widget child;

  MusicusBackend({
    @required this.dbPath,
    @required this.settingsStorage,
    @required this.playback,
    @required this.platform,
    @required this.child,
  });

  @override
  MusicusBackendState createState() => MusicusBackendState();

  static MusicusBackendState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InheritedBackend>().state;
}

class MusicusBackendState extends State<MusicusBackend> {
  /// Starts the Moor isolate.
  ///
  /// It will create a database connection for [request.path] and will send the
  /// Moor send port through [request.sendPort].
  static void _moorIsolateEntrypoint(_IsolateStartRequest request) {
    final executor = VmDatabase(File(request.path));
    final moorIsolate =
        MoorIsolate.inCurrent(() => DatabaseConnection.fromExecutor(executor));
    request.sendPort.send(moorIsolate.connectPort);
  }

  /// The current backend status.
  ///
  /// If this is not [MusicusBackendStatus.ready], the [child] widget should
  /// prevent all access to the backend.
  MusicusBackendStatus status = MusicusBackendStatus.loading;

  Database db;
  MusicusPlayback playback;
  MusicusSettings settings;
  MusicusClient client;
  MusicusPlatform platform;
  MusicusLibrary library;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Initialize resources.
  Future<void> _load() async {
    SendPort moorPort = IsolateNameServer.lookupPortByName('moor');
    if (moorPort == null) {
      final receivePort = ReceivePort();
      await Isolate.spawn(_moorIsolateEntrypoint,
          _IsolateStartRequest(receivePort.sendPort, widget.dbPath));
      moorPort = await receivePort.first;
      IsolateNameServer.registerPortWithName(moorPort, 'moor');
    }

    final moorIsolate = MoorIsolate.fromConnectPort(moorPort);
    db = Database.connect(await moorIsolate.connect());

    playback = widget.playback;
    await playback.setup();

    settings = MusicusSettings(widget.settingsStorage);
    await settings.load();

    settings.musicLibraryPath.listen((path) {
      setState(() {
        status = MusicusBackendStatus.loading;
      });
      _updateMusicLibrary(path);
    });

    settings.server.listen((serverSettings) {
      _updateClient(serverSettings);
    });

    _updateClient(settings.server.value);

    final path = settings.musicLibraryPath.value;

    platform = widget.platform;
    platform.setBasePath(path);

    // This will change the status for us.
    _updateMusicLibrary(path);
  }

  /// Create a music library according to [path].
  Future<void> _updateMusicLibrary(String path) async {
    if (path == null) {
      setState(() {
        status = MusicusBackendStatus.setup;
      });
    } else {
      platform.setBasePath(path);
      library = MusicusLibrary(path, platform);
      await library.load();
      setState(() {
        status = MusicusBackendStatus.ready;
      });
    }
  }

  /// Create a new client based on [settings].
  void _updateClient(MusicusServerSettings settings) {
    client?.dispose();
    client = MusicusClient(
      host: settings.host,
      port: settings.port,
      basePath: settings.apiPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedBackend(
      child: widget.child,
      state: this,
    );
  }

  @override
  void dispose() {
    super.dispose();

    settings.dispose();

    /// We don't stop the Moor isolate, because it can be used elsewhere.
    db.close();
    client.dispose();
  }
}

/// Bundles arguments for the moor isolate.
class _IsolateStartRequest {
  final SendPort sendPort;
  final String path;

  _IsolateStartRequest(this.sendPort, this.path);
}

/// Helper widget passing the current backend state down the widget tree.
class _InheritedBackend extends InheritedWidget {
  final Widget child;
  final MusicusBackendState state;

  _InheritedBackend({
    @required this.child,
    @required this.state,
  }) : super(child: child);

  @override
  bool updateShouldNotify(_InheritedBackend old) => true;
}
