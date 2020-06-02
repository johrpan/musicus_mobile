import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:moor/isolate.dart';
import 'package:musicus_client/musicus_client.dart';
import 'package:musicus_common/musicus_common.dart';
import 'package:musicus_player/musicus_player.dart';

const _portName = 'playbackService';

/// Entrypoint for the playback service.
void _playbackServiceEntrypoint() {
  AudioServiceBackground.run(() => _PlaybackService());
}

class Playback extends MusicusPlayback {
  StreamSubscription _playbackServiceStateSubscription;

  /// Start playback service.
  Future<void> _start() async {
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
    _setNormalizedPosition(positionMs / duration.value.inMilliseconds);
  }

  /// Update [position], [duration] and [normalizedPosition].
  void _updateDuration(int positionMs, int durationMs) {
    position.add(Duration(milliseconds: positionMs));
    duration.add(Duration(milliseconds: durationMs));
    _setNormalizedPosition(positionMs / durationMs);
  }

  /// Update [normalizedPosition] ensuring its value is between 0.0 and 1.0.
  void _setNormalizedPosition(double value) {
    if (value <= 0.0) {
      normalizedPosition.add(0.0);
    } else if (value >= 1.0) {
      normalizedPosition.add(1.0);
    } else {
      normalizedPosition.add(value);
    }
  }

  /// Update [currentIndex] and [currentTrack].
  ///
  /// Requires [playlist] to be up to date.
  void _updateCurrentTrack(int index) {
    currentIndex.add(index);
    currentTrack.add(playlist.value[index]);
  }

  @override
  Future<void> setup() async {
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
        dispose();
      } else {
        if (!active.value) {
          active.add(true);
        }

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

  @override
  Future<void> addTracks(List<InternalTrack> tracks) async {
    if (!AudioService.running) {
      await _start();
    }

    await AudioService.customAction('addTracks', jsonEncode(tracks));
  }

  @override
  Future<void> removeTrack(int index) async {
    if (AudioService.running) {
      await AudioService.customAction('removeTrack', index);
    }
  }

  @override
  Future<void> playPause() async {
    if (active.value) {
      if (playing.value) {
        await AudioService.pause();
      } else {
        await AudioService.play();
      }
    }
  }

  @override
  Future<void> seekTo(double pos) async {
    if (active.value && pos >= 0.0 && pos <= 1.0) {
      final durationMs = duration.value.inMilliseconds;
      await AudioService.seekTo((pos * durationMs).floor());
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (AudioService.running) {
      await AudioService.skipToPrevious();
    }
  }

  @override
  Future<void> skipToNext() async {
    if (AudioService.running) {
      await AudioService.skipToNext();
    }
  }

  @override
  Future<void> skipTo(int index) async {
    if (AudioService.running) {
      await AudioService.customAction('skipTo', index);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _playbackServiceStateSubscription.cancel();
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

  MusicusClientDatabase db;
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
    final moorPort = IsolateNameServer.lookupPortByName('moor');
    final moorIsolate = MoorIsolate.fromConnectPort(moorPort);
    db = MusicusClientDatabase.connect(connection: await moorIsolate.connect());
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

      final title = workInfo.composers
          .map((p) => '${p.firstName} ${p.lastName}')
          .join(', ');

      final subtitleBuffer = StringBuffer(workInfo.work.title);

      final partIds = track.track.partIds;
      if (partIds.isNotEmpty) {
        subtitleBuffer.write(': ');

        final section = workInfo.sections.lastWhere(
          (s) => s.beforePartIndex <= partIds[0],
          orElse: () => null,
        );

        if (section != null) {
          subtitleBuffer.write(section.title);
          subtitleBuffer.write(': ');
        }

        subtitleBuffer
            .write(partIds.map((i) => workInfo.parts[i].part.title).join(', '));
      }

      final subtitle = subtitleBuffer.toString();

      AudioServiceBackground.setMediaItem(MediaItem(
        id: track.identifier,
        album: subtitle,
        title: title,
        displayTitle: title,
        displaySubtitle: subtitle,
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
      _sendPosition();
      await Future.delayed(
          const Duration(milliseconds: positionUpdateInterval));
    }
  }

  /// Set the current track, update the player and notify the system.
  Future<void> _setCurrentTrack(int index) async {
    _currentTrack = index;
    _durationMs = await _player.setUri(_playlist[_currentTrack].identifier);
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
  Future<void> onCustomAction(String name, dynamic arguments) async {
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
