import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../widgets/play_pause_button.dart';
import '../widgets/recording_tile.dart';

class ProgramScreen extends StatefulWidget {
  @override
  _ProgramScreenState createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  MusicusBackendState backend;

  StreamSubscription<bool> playerActiveSubscription;

  StreamSubscription<List<String>> playlistSubscription;
  List<Widget> widgets = [];

  StreamSubscription<double> positionSubscription;
  double position = 0.0;
  bool seeking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = MusicusBackend.of(context);

    if (playerActiveSubscription != null) {
      playerActiveSubscription.cancel();
    }

    // Close the program screen, if the player is no longer active.
    playerActiveSubscription = backend.playback.active.listen((active) {
      if (!active) {
        Navigator.pop(context);
      }
    });

    if (playlistSubscription != null) {
      playlistSubscription.cancel();
    }

    playlistSubscription = backend.playback.playlist.listen((playlist) {
      updateProgram(playlist);
    });

    if (positionSubscription != null) {
      positionSubscription.cancel();
    }

    positionSubscription = backend.playback.normalizedPosition.listen((pos) {
      if (!seeking) {
        setState(() {
          position = pos;
        });
      }
    });
  }

  /// Go through the tracks of [playlist] and preprocess them for displaying.
  Future<void> updateProgram(List<String> playlist) async {
    List<Widget> newWidgets = [];

    // The following variables exist to adapt the resulting ProgramItem to its
    // predecessor.

    // If the previous recording was the same, we won't need to include the
    // recording data again.
    String lastRecordingId;

    // If the previous work was the same, we won't need to retrieve its parts
    // from the database again.
    String lastWorkId;

    // This will contain information on the last new work.
    WorkInfo workInfo;

    for (var i = 0; i < playlist.length; i++) {
      // The widgets displayed for this track.
      List<Widget> children = [];

      final track = await backend.db.tracksById(playlist[i]).getSingle();
      final recordingId = track.recording;
      final partIds = track.workParts;

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

      for (final part_id_unparsed in partIds.split(',')) {
        if (part_id_unparsed.isEmpty) {
          continue;
        }

        final partId = int.parse(part_id_unparsed);
        final partInfo = workInfo.parts[partId];

        children.add(Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
          ),
          child: Text(
            partInfo.title,
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
        stream: backend.playback.currentIndex,
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
                    backend.playback.skipTo(index);
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
                                  backend.playback.removeTrack(index);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        });
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
                backend.playback.seekTo(pos);
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
                    stream: backend.playback.position,
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
                    backend.playback.skipToPrevious();
                  },
                ),
                PlayPauseButton(),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () {
                    backend.playback.skipToNext();
                  },
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: StreamBuilder<Duration>(
                    stream: backend.playback.duration,
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
