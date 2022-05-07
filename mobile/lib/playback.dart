import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:musicus_common/musicus_common.dart';
import 'package:musicus_player/musicus_player.dart';
import 'package:path/path.dart' as p;

class MusicusMobilePlayback extends MusicusPlayback {
  AudioHandler audioHandler;
  MusicusLibrary library;

  @override
  Future<void> setup(MusicusLibrary musicusLibrary) async {
    library = musicusLibrary;

    audioHandler = await AudioService.init(
      builder: () => MusicusAudioHandler(musicusLibrary),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'de.johrpan.musicus.channel.audio',
        androidNotificationChannelName: 'Musicus playback',
        androidNotificationChannelDescription:
            'Keeps Musicus playing in the background',
        androidNotificationIcon: 'drawable/ic_notification',
      ),
    );

    listen();
  }

  Future<void> listen() async {
    audioHandler.customEvent.listen((event) {
      if (event != null && event is PlaylistEvent) {
        playlist.add(event.playlist);
      }
    });

    audioHandler.playbackState.listen((event) {
      if (event != null) {
        playing.add(event.playing);
        updatePosition(event.position);
        updateCurrentTrack(event.queueIndex);
      }
    });

    audioHandler.mediaItem.listen((event) {
      if (event != null) {
        updateDuration(event.duration);
      }
    });

    await audioHandler.customAction('sendState');
  }

  @override
  Future<void> addTracks(List<String> tracks) async {
    await audioHandler.customAction('addTracks', {'tracks': tracks});
    active.add(true);
  }

  @override
  Future<void> playPause() async {
    if (playing.value) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  }

  @override
  Future<void> removeTrack(int index) async {
    await audioHandler.customAction('removeTrack', {'index': index});
  }

  @override
  Future<void> seekTo(double pos) async {
    if (pos >= 0.0 && pos <= 1.0) {
      final durationMs = audioHandler.mediaItem.value.duration.inMilliseconds;
      await audioHandler
          .seek(Duration(milliseconds: (pos * durationMs).floor()));
    }
  }

  @override
  Future<void> skipTo(int index) async {
    await audioHandler.skipToQueueItem(index);
  }

  @override
  Future<void> skipToNext() async {
    await audioHandler.skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await audioHandler.skipToPrevious();
  }
}

class MusicusAudioHandler extends BaseAudioHandler {
  final MusicusLibrary library;

  MusicusPlayer player;

  List<String> playlist = [];
  int currentTrack = -1;
  int durationMs = 1000;
  bool playing = false;

  MusicusAudioHandler(this.library) {
    player = MusicusPlayer(onComplete: () async {
      if (currentTrack < playlist.length - 1) {
        await skipToNext();
      } else {
        playing = false;
        await sendState();
      }
    });
  }

  @override
  Future<void> play() async {
    await player.play();
    playing = true;
    await sendState();
    keepSendingPosition();
  }

  Future<void> pause() async {
    await player.pause();
    playing = false;
    await sendState();
  }

  Future<void> stop() async {
    playlist.clear();
    await player.stop();

    super.stop();
  }

  Future<void> seek(Duration position) async {
    await player.seekTo(position.inMilliseconds);
    await sendState();
  }

  @override
  Future<void> skipToPrevious() async {
    if (currentTrack > 0 && currentTrack < playlist.length) {
      await skipToQueueItem(currentTrack - 1);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (currentTrack >= 0 && currentTrack < playlist.length - 1) {
      await skipToQueueItem(currentTrack + 1);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < playlist.length) {
      currentTrack = index;
      final track = await library.db.tracksById(playlist[index]).getSingle();
      durationMs = await player.setUri(p.join(library.basePath, track.path));

      await sendState();
      await sendMediaItem();
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic> extras]) async {
    if (name == 'sendState') {
      await sendPlaylist();
      await sendMediaItem();
      await sendState();
    } else if (name == 'addTracks') {
      await addTracks(extras['tracks']);
    } else if (name == 'removeTrack') {
      await removeTrack(extras['index']);
    }
  }

  Future<void> addTracks(List<String> tracks) async {
    if (tracks != null && tracks.isNotEmpty) {
      final wasEmpty = playlist.isEmpty;

      playlist.addAll(tracks);
      await sendPlaylist();

      if (wasEmpty) {
        await skipToQueueItem(0);
        await play();
      } else {
        await sendState();
      }
    }
  }

  Future<void> removeTrack(int index) async {
    if (index >= 0 && index < playlist.length) {
      playlist.removeAt(index);

      if (playlist.isNotEmpty) {
        if (currentTrack == index) {
          await skipToQueueItem(index);
        } else if (currentTrack > index) {
          currentTrack--;
        }
      }

      await sendPlaylist();
      await sendState();
    }
  }

  Future<void> sendPlaylist() async {
    customEvent.add(PlaylistEvent(playlist));
  }

  Future<void> sendState() async {
    List<MediaControl> controls = [];
    Set<MediaAction> actions = {};

    if (playlist.isNotEmpty) {
      if (currentTrack < 0 || currentTrack >= playlist.length) {
        currentTrack = 0;
      }

      if (currentTrack > 0) {
        controls.add(MediaControl.skipToPrevious);
      }

      if (playing) {
        controls.add(MediaControl.pause);
      } else {
        controls.add(MediaControl.play);
      }

      if (currentTrack < playlist.length - 1) {
        controls.add(MediaControl.skipToNext);
      }

      actions.add(MediaAction.seek);
    } else {
      currentTrack = -1;
    }

    playbackState.add(PlaybackState(
      processingState: AudioProcessingState.ready,
      playing: playing,
      controls: controls,
      systemActions: actions,
      updatePosition: Duration(milliseconds: await player.getPosition()),
      queueIndex: currentTrack,
    ));
  }

  Future<void> sendMediaItem() async {
    if (currentTrack >= 0 && currentTrack < playlist.length) {
      final track =
          await library.db.tracksById(playlist[currentTrack]).getSingle();

      final recording =
          await library.db.recordingById(track.recording).getSingle();

      final workInfo = await library.db.getWork(recording.work);

      final partIds = track.workParts
          .split(',')
          .where((p) => p.isNotEmpty)
          .map((p) => int.parse(p))
          .toList();

      String title;
      String subtitle;

      if (workInfo != null) {
        title = '${workInfo.composer.firstName} ${workInfo.composer.lastName}';

        final subtitleBuffer = StringBuffer(workInfo.work.title);

        if (partIds.isNotEmpty) {
          subtitleBuffer.write(': ');
          subtitleBuffer
              .write(partIds.map((i) => workInfo.parts[i].title).join(', '));
        }

        subtitle = subtitleBuffer.toString();
      } else {
        title = '...';
        subtitle = '...';
      }

      mediaItem.add(MediaItem(
        id: track.id,
        title: subtitle,
        album: title,
        duration: Duration(milliseconds: durationMs),
      ));
    }
  }

  /// Notify the UI of the new playback position periodically.
  Future<void> keepSendingPosition() async {
    while (playing) {
      sendState();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

class PlaylistEvent {
  final List<String> playlist;
  PlaylistEvent(this.playlist);
}
