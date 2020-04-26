import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../music_library.dart';
import '../widgets/play_pause_button.dart';
import '../widgets/recording_tile.dart';

class ProgramScreen extends StatefulWidget {
  @override
  _ProgramScreenState createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  BackendState backend;

  StreamSubscription<bool> playerActiveSubscription;

  StreamSubscription<List<InternalTrack>> playlistSubscription;
  List<Widget> widgets = [];

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
    List<Widget> newWidgets = [];

    // The following variables exist to adapt the resulting ProgramItem to its
    // predecessor.

    // If the previous recording was the same, we won't need to include the
    // recording data again.
    int lastRecordingId;

    // If the previous work was the same, we won't need to retrieve its parts
    // from the database again.
    int lastWorkId;

    // This will contain information on the last new work.
    WorkInfo workInfo;

    for (var i = 0; i < playlist.length; i++) {
      // The widgets displayed for this track.
      List<Widget> children = [];

      final track = playlist[i];
      final recordingId = track.track.recordingId;
      final partIds = track.track.partIds;

      // If the recording is the same, the work will also be the same, so
      // workInfo doesn't have to be updated either.
      if (recordingId != lastRecordingId) {
        lastRecordingId = recordingId;

        final recordingInfo = await backend.db.getRecording(recordingId);

        if (recordingInfo.recording.work != lastWorkId) {
          lastWorkId = recordingInfo.recording.work;
          workInfo = await backend.db.getWork(lastWorkId);
        }

        children.addAll([
          RecordingTile(
            workInfo: workInfo,
            recordingInfo: recordingInfo,
          ),
          SizedBox(
            height: 8.0,
          ),
        ]);
      }

      for (final partId in partIds) {
        final partInfo = workInfo.parts[partId];

        children.add(Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
          ),
          child: Text(
            partInfo.work.title,
            style: TextStyle(
              fontStyle: FontStyle.italic,
            ),
          ),
        ));
      }

      newWidgets.add(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ));
    }

    // Check, whether we are still a part of the widget tree, because this
    // function might take some time.
    if (mounted) {
      setState(() {
        widgets = newWidgets;
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
              itemCount: widgets.length,
              itemBuilder: (context, index) {
                return InkWell(
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: index == snapshot.data
                            ? const Icon(Icons.play_arrow)
                            : SizedBox(
                                width: 24.0,
                                height: 24.0,
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: widgets[index],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    backend.player.skipTo(index);
                  },
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return SimpleDialog(
                          children: <Widget>[
                            ListTile(
                              title: Text('Remove from playlist'),
                              onTap: () {
                                backend.player.removeTrack(index);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      }
                    );
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
