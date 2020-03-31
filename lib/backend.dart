import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database.dart';

enum BackendStatus {
  loading,
  needsPermissions,
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
  final _permissionHandler = PermissionHandler();

  final playerActive = BehaviorSubject.seeded(false);
  final playing = BehaviorSubject.seeded(false);
  final position = BehaviorSubject.seeded(0.0);

  Database db;
  BackendStatus status = BackendStatus.loading;
  String musicLibraryPath;

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
    _shPref = await SharedPreferences.getInstance();
    musicLibraryPath = _shPref.getString('musicLibraryPath');

    db = Database('musicus.sqlite');

    final permissionStatus =
        await _permissionHandler.checkPermissionStatus(PermissionGroup.storage);

    if (permissionStatus != PermissionStatus.granted) {
      setState(() {
        status = BackendStatus.needsPermissions;
      });
    } else {
      await _loadMusicLibrary();
    }
  }

  Future<void> _loadMusicLibrary() async {
    if (musicLibraryPath == null) {
      setState(() {
        status = BackendStatus.setup;
      });
    } else {
      setState(() {
        status = BackendStatus.ready;
      });
    }
  }

  Future<void> requestPermissions() async {
    final result =
        await _permissionHandler.requestPermissions([PermissionGroup.storage]);

    if (result[PermissionGroup.storage] == PermissionStatus.granted) {
      _loadMusicLibrary();
    }
  }

  Future<void> openAppSettings() => _permissionHandler.openAppSettings();

  Future<void> setMusicLibraryPath(String path) async {
    musicLibraryPath = path;
    await _shPref.setString('musicLibraryPath', path);
    setState(() {
      status = BackendStatus.loading;
    });
    await _loadMusicLibrary();
  }

  void startPlayer() {
    playerActive.add(true);
  }

  void playPause() {
    playing.add(!playing.value);
    if (playing.value) {
      simulatePlay();
    }
  }

  void seekTo(double pos) {
    position.add(pos);
  }

  Future<void> simulatePlay() async {
    while (playing.value) {
      await Future.delayed(Duration(milliseconds: 200));
      if (position.value >= 0.99) {
        position.add(0.0);
      } else {
        position.add(position.value + 0.01);
      }
    }
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
