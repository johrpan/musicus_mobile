import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:moor/isolate.dart';
import 'package:musicus_database/musicus_database.dart';
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
  final currentIndex = BehaviorSubject.seeded(0);

  /// The currently played track.
  ///
  /// This will be null, if there is no  current track.
  final currentTrack = BehaviorSubject<InternalTrack>.seeded(null);

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

  /// Set everything to its default because the playback service was stopped.
  void _stop() {
    active.add(false);
    playlist.add([]);
    currentIndex.add(0);
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

  /// Update [position] and [normalizedPosition].
  ///
  /// Requires [duration] to be up to date
  void _updatePosition(int positionMs) {
    position.add(Duration(milliseconds: positionMs));
    normalizedPosition.add(positionMs / duration.value.inMilliseconds);
  }

  /// Update [position], [duration] and [normalizedPosition].
  void _updateDuration(int positionMs, int durationMs) {
    position.add(Duration(milliseconds: positionMs));
    duration.add(Duration(milliseconds: durationMs));
    normalizedPosition.add(positionMs / durationMs);
  }

  /// Update [currentIndex] and [currentTrack].
  ///
  /// Requires [playlist] to be up to date.
  void _updateCurrentTrack(int index) {
    currentIndex.add(index);
    currentTrack.add(playlist.value[index]);
  }

  /// Connect listeners and initialize streams.
  void setup() {
    if (_playbackServiceStateSubscription != null) {
      _playbackServiceStateSubscription.cancel();
    }

    // We will receive updated state information from the playback service,
    // which runs in its own isolate, through this port.
    final receivePort = ReceivePort();
    receivePort.asBroadcastStream(
      onListen: (subscription) {
        _playbackServiceStateSubscription = subscription;
      },
    ).listen((msg) {
      // If state is null, the background audio service has stopped.
      if (msg == null) {
        _stop();
      } else {
        if (msg is _StatusMessage) {
          playing.add(msg.playing);
        } else if (msg is _PositionMessage) {
          _updatePosition(msg.positionMs);
        } else if (msg is _TrackMessage) {
          _updateCurrentTrack(msg.currentTrack);
          _updateDuration(msg.positionMs, msg.durationMs);
        } else if (msg is _PlaylistMessage) {
          playlist.add(msg.playlist);
          _updateCurrentTrack(msg.currentTrack);
          _updateDuration(msg.positionMs, msg.durationMs);
        }
      }
    });

    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(receivePort.sendPort, _portName);

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

  /// Remove the track at [index] from the playlist.
  ///
  /// If the player is not active or an invalid value is provided, this will do
  /// nothing.
  Future<void> removeTrack(int index) async {
    if (AudioService.running) {
      await AudioService.customAction('removeTrack', index);
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
    playlist.close();
    currentIndex.close();
    currentTrack.close();
    playing.close();
    position.close();
    duration.close();
    normalizedPosition.close();
  }
}

/// A message from the playback service to the UI.
abstract class _Message {}

/// Playback status update.
class _StatusMessage extends _Message {
  /// Whether the player is playing (or paused).
  final bool playing;

  /// Playback position in milliseconds.
  final int positionMs;

  _StatusMessage({
    this.playing,
    this.positionMs,
  });
}

/// The playback position has changed.
///
/// This could be due to seeking or because time progressed.
class _PositionMessage extends _Message {
  /// Playback position in milliseconds.
  final int positionMs;

  _PositionMessage({
    this.positionMs,
  });
}

/// The current track has changed.
///
/// This also notifies about the playback position, as the old position could be
/// behind the new duration.
class _TrackMessage extends _Message {
  /// Index of the new track within the playlist.
  final int currentTrack;

  /// Duration of the new track in milliseconds.
  final int durationMs;

  /// Playback position in milliseconds.
  final int positionMs;

  _TrackMessage({
    this.currentTrack,
    this.durationMs,
    this.positionMs,
  });
}

/// The playlist was changed.
///
/// This also notifies about the current track, as the old index could be out of
/// range in the new playlist.
class _PlaylistMessage extends _Message {
  /// The new playlist.
  final List<InternalTrack> playlist;

  /// The current track.
  final int currentTrack;

  /// Duration of the current track in milliseconds.
  final int durationMs;

  /// Playback position in milliseconds.
  final int positionMs;

  _PlaylistMessage({
    this.playlist,
    this.currentTrack,
    this.durationMs,
    this.positionMs,
  });
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

  final _completer = Completer();
  final _loading = Completer();
  final List<InternalTrack> _playlist = [];

  Database db;
  MusicusPlayer _player;
  int _currentTrack = 0;
  bool _playing = false;
  int _durationMs = 1000;

  _PlaybackService() {
    _player = MusicusPlayer(onComplete: () async {
      if (_currentTrack < _playlist.length - 1) {
        await _setCurrentTrack(_currentTrack + 1);
        _sendTrack();
      } else {
        _playing = false;
        _sendStatus();
        _setState();
      }
    });

    _load();
  }

  /// Initialize database.
  Future<void> _load() async {
    final moorPort = IsolateNameServer.lookupPortByName('moorPort');
    final moorIsolate = MoorIsolate.fromConnectPort(moorPort);
    db = Database.connect(await moorIsolate.connect());
    _loading.complete();
  }

  /// Update the audio service status for the system.
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

    if (_playlist.isNotEmpty) {
      await _loading.future;

      final track = _playlist[_currentTrack];
      final recordingInfo = await db.getRecording(track.track.recordingId);
      final workInfo = await db.getWork(recordingInfo.recording.work);

      final composers = workInfo.composers
          .map((p) => '${p.firstName} ${p.lastName}')
          .join(', ');

      final title = workInfo.work.title;

      AudioServiceBackground.setMediaItem(MediaItem(
        id: track.uri,
        album: composers,
        title: title,
      ));
    }
  }

  /// Send a message to the UI.
  void _sendMsg(_Message msg) {
    final sendPort = IsolateNameServer.lookupPortByName(_portName);
    sendPort?.send(msg);
  }

  /// Notify the UI about the current playback status.
  Future<void> _sendStatus() async {
    _sendMsg(_StatusMessage(
      playing: _playing,
      positionMs: await _player.getPosition(),
    ));
  }

  /// Notify the UI about the current playback position.
  Future<void> _sendPosition() async {
    _sendMsg(_PositionMessage(
      positionMs: await _player.getPosition(),
    ));
  }

  /// Notify the UI about the current track.
  Future<void> _sendTrack() async {
    _sendMsg(_TrackMessage(
      currentTrack: _currentTrack,
      durationMs: _durationMs,
      positionMs: await _player.getPosition(),
    ));
  }

  /// Notify the UI about the current playlist.
  Future<void> _sendPlaylist() async {
    _sendMsg(_PlaylistMessage(
      playlist: _playlist,
      currentTrack: _currentTrack,
      durationMs: _durationMs,
      positionMs: await _player.getPosition(),
    ));
  }

  /// Notify the UI of the new playback position periodically.
  Future<void> _updatePosition() async {
    while (_playing) {
      await Future.delayed(
          const Duration(milliseconds: positionUpdateInterval));
      _sendPosition();
    }
  }

  /// Set the current track, update the player and notify the system.
  Future<void> _setCurrentTrack(int index) async {
    _currentTrack = index;
    _durationMs = await _player.setUri(_playlist[_currentTrack].uri);
    _setState();
  }

  /// Add [tracks] to the playlist.
  Future<void> _addTracks(List<InternalTrack> tracks) async {
    final play = _playlist.isEmpty;

    _playlist.addAll(tracks);
    if (play) {
      await _setCurrentTrack(0);
    }

    _sendPlaylist();
  }

  /// Remove the track at [index] from the playlist.
  ///
  /// If it was the current track, the next track will be played.
  Future<void> _removeTrack(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _playlist.removeAt(index);

      if (_playlist.isEmpty) {
        onStop();
      } else {
        if (_currentTrack == index) {
          await _setCurrentTrack(index);
        } else if (_currentTrack > index) {
          _currentTrack--;
        }

        _sendPlaylist();
      }
    }
  }

  /// Jump to the beginning of the track with the index [index].
  Future<void> _skipTo(int index) async {
    if (index >= 0 && index < _playlist.length) {
      await _setCurrentTrack(index);
      _sendTrack();
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
    // skipTo and removeTrack expect an integer as their argument.
    if (name == 'addTracks') {
      final tracksJson = jsonDecode(arguments);
      final List<InternalTrack> tracks = List.castFrom(
          tracksJson.map((j) => InternalTrack.fromJson(j)).toList());

      _addTracks(tracks);
    } else if (name == 'removeTrack') {
      final index = arguments as int;
      _removeTrack(index);
    } else if (name == 'skipTo') {
      final index = arguments as int;
      _skipTo(index);
    } else if (name == 'sendState') {
      _sendPlaylist();
      _sendStatus();
    }
  }

  @override
  void onPlay() {
    super.onPlay();

    _player.play();
    _playing = true;

    _sendStatus();
    _updatePosition();
    _setState();
  }

  @override
  void onPause() {
    super.onPause();

    _player.pause();
    _playing = false;

    _sendStatus();
    _setState();
  }

  @override
  Future<void> onSeekTo(int position) async {
    super.onSeekTo(position);

    await _player.seekTo(position);

    _sendPosition();
    _setState();
  }

  @override
  Future<void> onSkipToNext() async {
    super.onSkipToNext();

    if (_playlist.length > 1 && _currentTrack < _playlist.length - 1) {
      await _setCurrentTrack(_currentTrack + 1);
      _sendTrack();
    }
  }

  @override
  Future<void> onSkipToPrevious() async {
    super.onSkipToPrevious();

    // If more than five seconds of the current track have been played, go back
    // to its beginning, else, switch to the previous track.
    if (await _player.getPosition() > 5000) {
      await _setCurrentTrack(_currentTrack);
      _sendTrack();
    } else if (_playlist.length > 1 && _currentTrack > 0) {
      await _setCurrentTrack(_currentTrack - 1);
      _sendTrack();
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
