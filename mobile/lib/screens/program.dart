import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../music_library.dart';
import '../widgets/play_pause_button.dart';
import '../widgets/recording_tile.dart';

/// Data class to bundle information from the database on one track.
class ProgramItem {
  /// ID of the recording.
  ///
  /// We don't need the real recording, as the [RecordingTile] widget handles
  /// that for us. If the recording is the same one, as the one from the
  /// previous track, this will be null.
  final int recordingId;

  /// List of work parts contained in this track.
  ///
  /// This will include the parts linked in the track as well as all parents of
  /// them, if there are gaps between them (i.e. some parts are missing).
  final List<Work> workParts;

  ProgramItem({
    this.recordingId,
    this.workParts,
  });
}

/// Widget displaying a [ProgramItem].
class ProgramTile extends StatelessWidget {
  final ProgramItem item;
  final bool isPlaying;

  ProgramTile({
    this.item,
    this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: isPlaying
              ? const Icon(Icons.play_arrow)
              : SizedBox(
                  width: 24.0,
                  height: 24.0,
                ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (item.recordingId != null) ...[
                  RecordingTile(
                    recordingId: item.recordingId,
                  ),
                  SizedBox(
                    height: 8.0,
                  ),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final part in item.workParts)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8.0,
                        ),
                        child: Text(
                          part.title,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProgramScreen extends StatefulWidget {
  @override
  _ProgramScreenState createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  BackendState backend;

  StreamSubscription<bool> playerActiveSubscription;

  StreamSubscription<List<InternalTrack>> playlistSubscription;
  List<ProgramItem> items = [];

  StreamSubscription<double> positionSubscription;
  double position = 0.0;
  bool seeking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = Backend.of(context);

    if (playerActiveSubscription != null) {
      playerActiveSubscription.cancel();
    }

    // Close the program screen, if the player is no longer active.
    playerActiveSubscription = backend.player.active.listen((active) {
      if (!active) {
        Navigator.pop(context);
      }
    });

    if (playlistSubscription != null) {
      playlistSubscription.cancel();
    }

    playlistSubscription = backend.player.playlist.listen((playlist) {
      updateProgram(playlist);
    });

    if (positionSubscription != null) {
      positionSubscription.cancel();
    }

    positionSubscription = backend.player.normalizedPosition.listen((pos) {
      if (!seeking) {
        setState(() {
          position = pos;
        });
      }
    });
  }

  /// Go through the tracks of [playlist] and preprocess them for displaying.
  Future<void> updateProgram(List<InternalTrack> playlist) async {
    List<ProgramItem> newItems = [];

    // The following variables exist to adapt the resulting ProgramItem to its
    // predecessor.

    // If the previous recording was the same, we won't need to include the
    // recording data again.
    int lastRecordingId;

    // If the previous work was the same, we won't need to retrieve its parts
    // from the database again.
    int lastWorkId;

    // This will always contain the parts of the current work.
    List<Work> workParts = [];

    for (var i = 0; i < playlist.length; i++) {
      // The data that will be stored in the resulting ProgramItem.
      int newRecordingId;
      List<Work> newWorkParts = [];

      final track = playlist[i];
      final recordingId = track.track.recordingId;
      final partIds = track.track.partIds;

      // newRecordingId will be null, if the recording ID is the same. This
      // also means, that the work is the same, so workParts doesn't have to
      // be updated either.
      if (recordingId != lastRecordingId) {
        lastRecordingId = recordingId;
        newRecordingId = recordingId;

        final recording =
            await backend.db.recordingById(recordingId).getSingle();

        if (recording.work != lastWorkId) {
          workParts = await backend.db.workParts(recording.work).get();
        }

        lastWorkId = recording.work;
      }

      for (final partId in partIds) {
        newWorkParts.add(workParts[partId]);
      }

      newItems.add(ProgramItem(
        recordingId: newRecordingId,
        workParts: newWorkParts,
      ));
    }

    // Check, whether we are still a part of the widget tree, because this
    // function might take some time.
    if (mounted) {
      setState(() {
        items = newItems;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Program'),
      ),
      body: StreamBuilder<int>(
        stream: backend.player.currentIndex,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return InkWell(
                  child: ProgramTile(
                    item: items[index],
                    isPlaying: index == snapshot?.data,
                  ),
                  onTap: () {
                    backend.player.skipTo(index);
                  },
                );
              },
            );
          } else {
            return Container();
          }
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Slider(
              value: position,
              onChangeStart: (_) {
                seeking = true;
              },
              onChangeEnd: (pos) {
                seeking = false;
                backend.player.seekTo(pos);
              },
              onChanged: (pos) {
                setState(() {
                  position = pos;
                });
              },
            ),
            Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 24.0),
                  child: StreamBuilder<Duration>(
                    stream: backend.player.position,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return DurationText(snapshot.data);
                      } else {
                        return Container();
                      }
                    },
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () {
                    backend.player.skipToPrevious();
                  },
                ),
                PlayPauseButton(),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () {
                    backend.player.skipToNext();
                  },
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: StreamBuilder<Duration>(
                    stream: backend.player.duration,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return DurationText(snapshot.data);
                      } else {
                        return Container();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    playerActiveSubscription.cancel();
    playlistSubscription.cancel();
    positionSubscription.cancel();
  }
}

class DurationText extends StatelessWidget {
  final Duration duration;

  DurationText(this.duration);

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes;
    final seconds = (duration - Duration(minutes: minutes)).inSeconds;

    final secondsString = seconds >= 10 ? seconds.toString() : '0$seconds';

    return Text('$minutes:$secondsString');
  }
}
