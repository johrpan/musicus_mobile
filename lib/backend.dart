import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database.dart';

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

  final playerActive = BehaviorSubject.seeded(false);
  final playing = BehaviorSubject.seeded(false);
  final position = BehaviorSubject.seeded(0.0);

  BackendStatus status = BackendStatus.loading;
  Database db;
  String musicLibraryUri;

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
    db = Database('musicus.sqlite');
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
