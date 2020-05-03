import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../editors/work.dart';
import '../widgets/texts.dart';
import '../widgets/lists.dart';

class WorkScreen extends StatelessWidget {
  final WorkInfo workInfo;

  WorkScreen({
    this.workInfo,
  });

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

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
          return await backend.client.getRecordings(workInfo.work.id, page);
        },
        builder: (context, recordingInfo) => ListTile(
          title: PerformancesText(
            performanceInfos: recordingInfo.performances,
          ),
          onTap: () {
            final tracks = backend.ml.tracks[recordingInfo.recording.id];
            tracks.sort((t1, t2) => t1.track.index.compareTo(t2.track.index));

            backend.player
                .addTracks(backend.ml.tracks[recordingInfo.recording.id]);
          },
        ),
      ),
    );
  }
}
