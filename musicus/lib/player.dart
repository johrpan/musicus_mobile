import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:musicus_player/musicus_player.dart';
import 'package:rxdart/rxdart.dart';

import 'music_library.dart';

/// Entrypoint for the playback service.
void _playbackServiceEntrypoint() {
  AudioServiceBackground.run(() => _PlaybackService());
}

class Player {
  /// The interval between playback position updates in milliseconds.
  static const positionUpdateInterval = 250;

  /// Whether the player is active.
  ///
  /// This means, that there is at least one item in the queue and the playback
  /// service is ready to play.
  final active = BehaviorSubject.seeded(false);

  /// Whether we are currently playing or not.
  ///
  /// This will be false, if the player is not active.
  final playing = BehaviorSubject.seeded(false);

  /// Current playback position.
  ///
  /// If the player is not active, this will default to zero.
  final position = BehaviorSubject.seeded(const Duration());

  /// Duration of the current track.
  ///
  /// If the player is not active, the duration will default to 1 s.
  final duration = BehaviorSubject.seeded(const Duration(seconds: 1));

  /// Playback position normalized to the range from zero to one.
  final normalizedPosition = BehaviorSubject.seeded(0.0);

  /// The current position in milliseconds.
  int _positionMs = 0;

  StreamSubscription<PlaybackState> _stateStreamSubscription;
  StreamSubscription<MediaItem> _mediaItemStreamSubscription;

  /// Update [position] and [normalizedPosition] according to [_positionMs].
  void _updatePosition() {
    position.add(Duration(milliseconds: _positionMs));
    normalizedPosition.add(_positionMs / duration.value.inMilliseconds);
  }

  /// Set everything to its default because the playback service was stopped.
  void _stop() {
    active.add(false);
    playing.add(false);
    position.add(const Duration());
    duration.add(const Duration(seconds: 1));
    normalizedPosition.add(0.0);
    _positionMs = 0;
    _stateStreamSubscription.cancel();
    _mediaItemStreamSubscription.cancel();
  }

  /// Start playback service.
  Future<void> start() async {
    if (!AudioService.running) {
      await AudioService.start(
        backgroundTaskEntrypoint: _playbackServiceEntrypoint,
        androidNotificationChannelName: 'Musicus playback',
        androidNotificationChannelDescription:
            'Keeps Musicus playing in the background',
        androidNotificationIcon: 'drawable/ic_notification',
      );

      setup();
    }
  }

  /// Connect listeners and initialize streams.
  void setup() {
    if (AudioService.running) {
      active.add(true);

      _stateStreamSubscription =
          AudioService.playbackStateStream.listen((playbackState) {
        if (playbackState != null) {
          if (playbackState.basicState == BasicPlaybackState.stopped) {
            _stop();
          } else {
            if (playbackState.basicState == BasicPlaybackState.playing) {
              playing.add(true);
              _play();
            } else {
              playing.add(false);
            }

            _positionMs = playbackState.currentPosition;
            _updatePosition();
          }
        }
      });

      _mediaItemStreamSubscription =
          AudioService.currentMediaItemStream.listen((mediaItem) {
        if (mediaItem?.duration != null) {
          duration.add(Duration(milliseconds: mediaItem.duration));
        }
      });
    }
  }

  /// Toggle whether the player is playing or paused.
  ///
  /// If the player is not active, this will do nothing.
  Future<void> playPause() async {
    if (active.value) {
      if (playing.value) {
        await AudioService.pause();
      } else {
        await AudioService.play();
      }
    }
  }

  /// Add a list of tracks to the players playlist.
  Future<void> addTracks(List<InternalTrack> tracks) async {
    if (!AudioService.running) {
      await start();
    }

    await AudioService.customAction('addTracks', jsonEncode(tracks));
  }

  /// Regularly update [_positionMs] while playing.
  // TODO: Maybe find a better approach on handling this.
  Future<void> _play() async {
    while (playing.value) {
      await Future.delayed(Duration(milliseconds: positionUpdateInterval));
      _positionMs += positionUpdateInterval;
      _updatePosition();
    }
  }

  /// Seek to [pos], which is a value between (and including) zero and one.
  ///
  /// If the player is not active or an invalid value is provided, this will do
  /// nothing.
  Future<void> seekTo(double pos) async {
    if (active.value && pos >= 0.0 && pos <= 1.0) {
      final durationMs = duration.value.inMilliseconds;
      await AudioService.seekTo((pos * durationMs).floor());
    }
  }

  /// Tidy up.
  void dispose() {
    _stateStreamSubscription.cancel();
    _mediaItemStreamSubscription.cancel();

    active.close();
    playing.close();
    position.close();
    duration.close();
    normalizedPosition.close();
  }
}

class _PlaybackService extends BackgroundAudioTask {
  static const playControl = MediaControl(
    androidIcon: 'drawable/ic_play',
    label: 'Play',
    action: MediaAction.play,
  );

  static const pauseControl = MediaControl(
    androidIcon: 'drawable/ic_pause',
    label: 'Pause',
    action: MediaAction.pause,
  );

  static const stopControl = MediaControl(
    androidIcon: 'drawable/ic_stop',
    label: 'Stop',
    action: MediaAction.stop,
  );

  static const dummyMediaItem = MediaItem(
    id: 'dummy',
    album: 'Johannes Brahms',
    title: 'Symphony No. 1 in C minor, Op. 68: 1. Un poco sostenuto — Allegro',
    duration: 10000,
  );

  final _completer = Completer();
  final List<InternalTrack> _playlist = [];

  MusicusPlayer _player;
  int _currentTrack = 0;
  int _position;
  int _updateTime;
  bool _playing = false;

  _PlaybackService() {
    _player = MusicusPlayer(onComplete: () {
      // TODO: Go to next track.
    });
  }

  void _setPosition(int position) {
    _position = position;
    _updateTime = DateTime.now().millisecondsSinceEpoch;
  }

  void _setState() {
    AudioServiceBackground.setState(
      controls:
          _playing ? [pauseControl, stopControl] : [playControl, stopControl],
      basicState:
          _playing ? BasicPlaybackState.playing : BasicPlaybackState.paused,
      position: _position,
      updateTime: _updateTime,
    );

    AudioServiceBackground.setMediaItem(dummyMediaItem);
  }

  @override
  Future<void> onStart() async {
    _setPosition(0);
    _setState();
    await _completer.future;
  }

  @override
  void onCustomAction(String name, dynamic arguments) {
    super.onCustomAction(name, arguments);

    // addTracks expects a List<Map<String, dynamic>> as its argument.
    if (name == 'addTracks') {
      final tracksJson = jsonDecode(arguments);
      final List<InternalTrack> tracks = List.castFrom(
          tracksJson.map((j) => InternalTrack.fromJson(j)).toList());
      _playlist.addAll(tracks);
      _player.setUri(tracks.first.uri);
    }
  }

  @override
  void onPlay() {
    super.onPlay();

    _player.play();
    _playing = true;
    _setState();
  }

  @override
  void onPause() {
    super.onPause();

    _player.pause();
    _playing = false;
    _setState();
  }

  @override
  void onSeekTo(int position) {
    super.onSeekTo(position);

    _setPosition(position);
    _setState();
  }

  @override
  void onStop() {
    _player.stop();

    AudioServiceBackground.setState(
      controls: [],
      basicState: BasicPlaybackState.stopped,
    );

    // This will end onStart.
    _completer.complete();
  }
}
