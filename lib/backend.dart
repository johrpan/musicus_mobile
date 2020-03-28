import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import 'database.dart';

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
  final db = Database('musicus.sqlite');

  final playerActive = BehaviorSubject.seeded(false);
  final playing = BehaviorSubject.seeded(false);
  final position = BehaviorSubject.seeded(0.0);

  @override
  Widget build(BuildContext context) {
    return _InheritedBackend(
      child: widget.child,
      state: this,
    );
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
  bool updateShouldNotify(_InheritedBackend old) => state != old.state;
}
