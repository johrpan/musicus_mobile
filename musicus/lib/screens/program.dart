import 'dart:async';

import 'package:flutter/material.dart';

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
  StreamSubscription<double> positionSubscription;
  double position = 0.0;
  bool seeking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = Backend.of(context);

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
      body: StreamBuilder<List<InternalTrack>>(
        stream: backend.player.playlist,
        builder: (context, snapshot) {
          final playlist = snapshot.data;

          if (playlist != null && playlist.isNotEmpty) {
            return StreamBuilder<int>(
              stream: backend.player.currentIndex,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: playlist.length,
                    itemBuilder: (context, index) {
                      
                      final track = playlist[index];

                      return ListTile(
                        leading: index == snapshot.data
                            ? const Icon(Icons.play_arrow)
                            : SizedBox(
                                width: 24.0,
                                height: 24.0,
                              ),
                        title: RecordingTile(
                          recordingId: track.track.recordingId,
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
