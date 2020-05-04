import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musicus_common/musicus_common.dart';

class PlayPauseButton extends StatefulWidget {
  @override
  _PlayPauseButtonState createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton>
    with SingleTickerProviderStateMixin {
  AnimationController playPauseAnimation;
  MusicusBackendState backend;
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

    backend = MusicusBackend.of(context);
    playPauseAnimation.value = backend.playback.playing.value ? 1.0 : 0.0;

    if (playingSubscription != null) {
      playingSubscription.cancel();
    }

    playingSubscription = backend.playback.playing.listen((playing) =>
        playing ? playPauseAnimation.forward() : playPauseAnimation.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: playPauseAnimation,
      ),
      onPressed: backend.playback.playPause,
    );
  }

  @override
  void dispose() {
    super.dispose();
    playingSubscription.cancel();
  }
}
