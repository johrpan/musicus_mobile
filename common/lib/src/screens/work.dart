import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../widgets/lists.dart';
import '../widgets/texts.dart';

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
          );
        },
      ),
    );
  }
}
