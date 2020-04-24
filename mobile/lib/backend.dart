import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:moor_ffi/moor_ffi.dart';
import 'package:musicus_database/musicus_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:shared_preferences/shared_preferences.dart';

import 'music_library.dart';
import 'player.dart';

// The following code was taken from
// https://moor.simonbinder.eu/docs/advanced-features/isolates/ and just
// slightly modified.

Future<MoorIsolate> _createMoorIsolate() async {
  // This method is called from the main isolate. Since we can't use
  // getApplicationDocumentsDirectory on a background isolate, we calculate
  // the database path in the foreground isolate and then inform the
  // background isolate about the path.
  final dir = await pp.getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'db.sqlite');
  final receivePort = ReceivePort();

  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(receivePort.sendPort, path),
  );

  // _startBackground will send the MoorIsolate to this ReceivePort.
  return (await receivePort.first as MoorIsolate);
}

void _startBackground(_IsolateStartRequest request) {
  // This is the entrypoint from the background isolate! Let's create
  // the database from the path we received.
  final executor = VmDatabase(File(request.targetPath));
  // We're using MoorIsolate.inCurrent here as this method already runs on a
  // background isolate. If we used MoorIsolate.spawn, a third isolate would be
  // started which is not what we want!
  final moorIsolate = MoorIsolate.inCurrent(
    () => DatabaseConnection.fromExecutor(executor),
  );
  // Inform the starting isolate about this, so that it can call .connect().
  request.sendMoorIsolate.send(moorIsolate);
}

// Used to bundle the SendPort and the target path, since isolate entrypoint
// functions can only take one parameter.
class _IsolateStartRequest {
  final SendPort sendMoorIsolate;
  final String targetPath;

  _IsolateStartRequest(this.sendMoorIsolate, this.targetPath);
}

enum BackendStatus {
  loading,
  setup,
  ready,
}

class Backend extends StatefulWidget {
  final Widget child;

  Backend({
    @required this.child,
  });

  @override
  BackendState createState() => BackendState();

  static BackendState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InheritedBackend>().state;
}

class BackendState extends State<Backend> {
  static const _platform = MethodChannel('de.johrpan.musicus/platform');

  final player = Player();

  BackendStatus status = BackendStatus.loading;
  Database db;
  String musicLibraryUri;
  MusicLibrary ml;

  MoorIsolate _moorIsolate;
  SharedPreferences _shPref;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedBackend(
      child: widget.child,
      state: this,
    );
  }

  Future<void> _load() async {
    _moorIsolate = await _createMoorIsolate();
    final dbConnection = await _moorIsolate.connect();
    player.setup();
    db = Database.connect(dbConnection);

    _shPref = await SharedPreferences.getInstance();
    musicLibraryUri = _shPref.getString('musicLibraryUri');

    _loadMusicLibrary();
  }

  Future<void> _loadMusicLibrary() async {
    if (musicLibraryUri == null) {
      setState(() {
        status = BackendStatus.setup;
      });
    } else {
      ml = MusicLibrary(musicLibraryUri);
      await ml.load();
      setState(() {
        status = BackendStatus.ready;
      });
    }
  }

  Future<void> chooseMusicLibraryUri() async {
    final uri = await _platform.invokeMethod<String>('openTree');

    if (uri != null) {
      musicLibraryUri = uri;
      await _shPref.setString('musicLibraryUri', uri);
      setState(() {
        status = BackendStatus.loading;
      });
      await _loadMusicLibrary();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _moorIsolate.shutdownAll();
  }
}

class _InheritedBackend extends InheritedWidget {
  final Widget child;
  final BackendState state;

  _InheritedBackend({
    @required this.child,
    @required this.state,
  }) : super(child: child);

  @override
  bool updateShouldNotify(_InheritedBackend old) => true;
}
