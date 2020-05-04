import 'package:flutter/material.dart';
import 'package:musicus_common/musicus_common.dart';
import 'package:musicus_database/musicus_database.dart';

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
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkEditor(
                    workInfo: workInfo,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
        ],
      ),
      body: PagedListView<RecordingInfo>(
        fetch: (page, _) async {
          return await backend.db.getRecordings(workInfo.work.id, page);
        },
        builder: (context, recordingInfo) => ListTile(
          title: PerformancesText(
            performanceInfos: recordingInfo.performances,
          ),
          onTap: () {
            final tracks = backend.library.tracks[recordingInfo.recording.id];
            tracks.sort((t1, t2) => t1.track.index.compareTo(t2.track.index));

            backend.playback
                .addTracks(backend.library.tracks[recordingInfo.recording.id]);
          },
        ),
      ),
    );
  }
}
