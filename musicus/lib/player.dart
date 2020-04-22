import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:musicus_player/musicus_player.dart';
import 'package:rxdart/rxdart.dart';

import 'music_library.dart';

const _portName = 'playbackService';

/// Entrypoint for the playback service.
void _playbackServiceEntrypoint() {
  AudioServiceBackground.run(() => _PlaybackService());
}

class Player {
  /// Whether the player is active.
  ///
  /// This means, that there is at least one item in the queue and the playback
  /// service is ready to play.
  final active = BehaviorSubject.seeded(false);

  /// The current playlist.
  ///
  /// If the player is not active, this will be an empty list.
  final playlist = BehaviorSubject.seeded(<InternalTrack>[]);

  /// Index of the currently played (or paused) track within the playlist.
  ///
  /// This will be zero, if the player is not active!
  final currentTrack = BehaviorSubject.seeded(0);

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

  StreamSubscription _playbackServiceStateSubscription;

  /// Update [position] and [normalizedPosition] from position in milliseconds.
  void _updatePosition(int positionMs) {
    position.add(Duration(milliseconds: positionMs));
    normalizedPosition.add(positionMs / duration.value.inMilliseconds);
  }

  /// Set everything to its default because the playback service was stopped.
  void _stop() {
    active.add(false);
    playlist.add([]);
    currentTrack.add(0);
    playing.add(false);
    position.add(const Duration());
    duration.add(const Duration(seconds: 1));
    normalizedPosition.add(0.0);
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

      active.add(true);
    }
  }

  /// Connect listeners and initialize streams.
  void setup() {
    if (_playbackServiceStateSubscription == null) {
      // We will receive updated state information from the playback service,
      // which runs in its own isolate, through this port.
      final receivePort = ReceivePort();
      _playbackServiceStateSubscription = receivePort.listen((msg) {
        // If state is null, the background audio service has stopped.
        if (msg == null) {
          _stop();
        } else {
          final state = msg as PlaybackServiceState;

          // TODO: Consider checking, whether values have actually changed.
          playlist.add(state.playlist);
          currentTrack.add(state.currentTrack);
          playing.add(state.playing);
          position.add(Duration(milliseconds: state.positionMs));
          duration.add(Duration(milliseconds: state.durationMs));
          normalizedPosition.add(state.positionMs / state.durationMs);
        }
      });
      IsolateNameServer.registerPortWithName(receivePort.sendPort, _portName);
    }

    if (AudioService.running) {
      active.add(true);

      // Instruct the background service to send its current state. This will
      // by handled in the listeners, that were already set in the constructor.
      AudioService.customAction('sendState');
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

  /// Play the previous track in the playlist.
  /// 
  /// If the player is not active or there is no previous track, this will do
  /// nothing.
  Future<void> skipToNext() async {
    if (AudioService.running) {
      await AudioService.skipToNext();
    }
  }

  /// Skip to the next track in the playlist.
  /// 
  /// If the player is not active or there is no next track, this will do
  /// nothing. If more than five seconds of the current track have been played,
  /// this will go back to its beginning instead.
  Future<void> skipToPrevious() async {
    if (AudioService.running) {
      await AudioService.skipToPrevious();
    }
  }

  /// Switch to the track with the index [index] in the playlist.
  Future<void> skipTo(int index) async {
    if (AudioService.running) {
      await AudioService.customAction('skipTo', index);
    }
  }

  /// Tidy up.
  void dispose() {
    _playbackServiceStateSubscription.cancel();
    active.close();
    playing.close();
    position.close();
    duration.close();
    normalizedPosition.close();
  }
}

/// Bundle of the current state of the playback service.
class PlaybackServiceState {
  /// The current playlist.
  final List<InternalTrack> playlist;

  /// The index of the currentTrack.
  final int currentTrack;

  /// Whether the player is playing (or paused).
  final bool playing;

  /// The current playback position in milliseconds.
  final int positionMs;

  /// The duration of the currently played track in milliseconds.
  final int durationMs;

  PlaybackServiceState({
    this.playlist,
    this.currentTrack,
    this.playing,
    this.positionMs,
    this.durationMs,
  });

  factory PlaybackServiceState.fromJson(Map<String, dynamic> json) =>
      PlaybackServiceState(
        playlist: json['playlist']
            .map<InternalTrack>((j) => InternalTrack.fromJson(j))
            .toList(),
        currentTrack: json['currentTrack'],
        playing: json['playing'],
        positionMs: json['positionMs'],
        durationMs: json['durationMs'],
      );

  Map<String, dynamic> toJson() => {
        'playlist': playlist.map((t) => t.toJson()),
        'currentTrack': currentTrack,
        'playing': playing,
        'positionMs': positionMs,
        'durationMs': durationMs,
      };
}

class _PlaybackService extends BackgroundAudioTask {
  /// The interval between playback position updates in milliseconds.
  static const positionUpdateInterval = 250;

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
  bool _playing = false;
  int _durationMs = 1000;

  _PlaybackService() {
    _player = MusicusPlayer(onComplete: () {
      // TODO: Go to next track.
    });
  }

  Future<void> _sendMsg(dynamic msg) {
    final sendPort = IsolateNameServer.lookupPortByName(_portName);
    sendPort?.send(msg);
  }

  Future<void> _setState() async {
    final positionMs = await _player.getPosition() ?? 0;
    final updateTime = DateTime.now().millisecondsSinceEpoch;

    AudioServiceBackground.setState(
      controls:
          _playing ? [pauseControl, stopControl] : [playControl, stopControl],
      basicState:
          _playing ? BasicPlaybackState.playing : BasicPlaybackState.paused,
      position: positionMs,
      updateTime: updateTime,
    );

    AudioServiceBackground.setMediaItem(dummyMediaItem);

    _sendMsg(PlaybackServiceState(
      playlist: _playlist,
      currentTrack: _currentTrack,
      playing: _playing,
      positionMs: positionMs,
      durationMs: _durationMs,
    ));
  }

  Future<void> _updatePosition() async {
    while (_playing) {
      await Future.delayed(
          const Duration(milliseconds: positionUpdateInterval));

      // TODO: Consider seperating position updates from general state updates
      // and/or estimating the position instead of asking the player.
      _setState();
    }
  }

  @override
  Future<void> onStart() async {
    _setState();
    await _completer.future;
  }

  @override
  void onCustomAction(String name, dynamic arguments) {
    super.onCustomAction(name, arguments);

    // addTracks expects a List<Map<String, dynamic>> as its argument.
    // skipTo expects an integer as its argument.
    if (name == 'addTracks') {
      final tracksJson = jsonDecode(arguments);
      final List<InternalTrack> tracks = List.castFrom(
          tracksJson.map((j) => InternalTrack.fromJson(j)).toList());
      _playlist.addAll(tracks);
      _player.setUri(tracks.first.uri).then((newDurationMs) {
        _durationMs = newDurationMs;
        _setState();
      });
    }
    if (name == 'skipTo') {
      final index = arguments as int;

      if (index >= 0 && index < _playlist.length) {
        _currentTrack = index;
        _player.setUri(_playlist[index].uri);
        _setState();
      }
    } else if (name == 'sendState') {
      // Send the current state to the main isolate.
      _setState();
    }
  }

  @override
  void onPlay() {
    super.onPlay();

    _player.play();
    _playing = true;
    _updatePosition();
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

    _player.seekTo(position).then((_) {
      _setState();
    });
  }

  @override
  void onSkipToNext() {
    super.onSkipToNext();

    if (_playlist.length > 1 && _currentTrack < _playlist.length - 1) {
      _currentTrack++;
      _player.setUri(_playlist[_currentTrack].uri);
      _setState();
    }
  }

  @override
  void onSkipToPrevious() async {
    super.onSkipToPrevious();

    // If more than five seconds of the current track have been played, go back
    // to its beginning, else, switch to the previous track.
    if (await _player.getPosition() > 5000) {
      await _player.setUri(_playlist[_currentTrack].uri);
      _setState();
    } else if (_playlist.length > 1 && _currentTrack > 0) {
      _currentTrack--;
      _player.setUri(_playlist[_currentTrack].uri);
      _setState();
    }
  }

  @override
  void onStop() {
    _player.stop();

    AudioServiceBackground.setState(
      controls: [],
      basicState: BasicPlaybackState.stopped,
    );

    _sendMsg(null);

    // This will end onStart.
    _completer.complete();
  }
}
