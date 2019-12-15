import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import 'database.dart';

class Backend extends InheritedWidget {
  static Backend of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Backend>();

  final Widget child;

  final db = Database('musicus.sqlite');

  final playerActive = BehaviorSubject.seeded(false);
  final playing = BehaviorSubject.seeded(false);
  final position = BehaviorSubject.seeded(0.0);

  Backend({
    @required this.child,
  }) : super(child: child);

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

  @override
  bool updateShouldNotify(Backend old) =>
      playerActive != old.playerActive ||
      playing != old.playing ||
      position != old.position;
}
