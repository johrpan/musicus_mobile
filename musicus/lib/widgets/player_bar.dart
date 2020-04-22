import 'package:flutter/material.dart';
import 'package:musicus/database.dart';

import '../backend.dart';
import '../music_library.dart';
import '../screens/program.dart';

import 'play_pause_button.dart';
import 'texts.dart';

class PlayerBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return BottomAppBar(
      child: InkWell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            StreamBuilder(
              stream: backend.player.normalizedPosition,
              builder: (context, snapshot) => LinearProgressIndicator(
                value: snapshot.data,
              ),
            ),
            Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.keyboard_arrow_up),
                ),
                Expanded(
                  child: StreamBuilder<InternalTrack>(
                    stream: backend.player.currentTrack,
                    builder: (context, snapshot) {
                      if (snapshot.data != null) {
                        final recordingId = snapshot.data.track.recordingId;

                        return FutureBuilder<Recording>(
                          future:
                              backend.db.recordingById(recordingId).getSingle(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final workId = snapshot.data.work;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  DefaultTextStyle.merge(
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    child: ComposersText(workId),
                                  ),
                                  WorkText(workId),
                                ],
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
                ),
                PlayPauseButton(),
              ],
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProgramScreen(),
          ),
        ),
      ),
    );
  }
}
