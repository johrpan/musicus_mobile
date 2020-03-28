import 'dart:async';

import 'package:flutter/material.dart';

import '../backend.dart';

class PlayPauseButton extends StatefulWidget {
  @override
  _PlayPauseButtonState createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton>
    with SingleTickerProviderStateMixin {
  AnimationController playPauseAnimation;
  BackendState backend;
  StreamSubscription<bool> playingSubscription;

  @override
  void initState() {
    super.initState();

    playPauseAnimation = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = Backend.of(context);
    playPauseAnimation.value = backend.playing.value ? 1.0 : 0.0;

    if (playingSubscription != null) {
      playingSubscription.cancel();
    }

    playingSubscription = backend.playing.listen((playing) =>
        playing ? playPauseAnimation.forward() : playPauseAnimation.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: playPauseAnimation,
      ),
      onPressed: backend.playPause,
    );
  }

  @override
  void dispose() {
    super.dispose();
    playingSubscription.cancel();
  }
}
