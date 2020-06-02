import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';
import 'package:musicus_common/musicus_common.dart';

class WorkScreen extends StatelessWidget {
  final WorkInfo workInfo;

  WorkScreen({
    this.workInfo,
  });

  @override
  Widget build(BuildContext context) {
    final backend = MusicusBackend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(workInfo.work.title),
      ),
      body: PagedListView<RecordingInfo>(
        fetch: (page, _) async {
          return await backend.db.getRecordings(workInfo.work.id, page);
        },
        builder: (context, recordingInfo) {
          final recordingId = recordingInfo.recording.id;

          return ListTile(
            title: PerformancesText(
              performanceInfos: recordingInfo.performances,
            ),
            onTap: () {
              final tracks = backend.library.tracks[recordingId];
              tracks.sort((t1, t2) => t1.track.index.compareTo(t2.track.index));
              backend.playback.addTracks(tracks);
            },
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    children: <Widget>[
                      ListTile(
                        title: Text('Edit recording'),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecordingEditor(
                                recordingInfo: recordingInfo,
                              ),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
