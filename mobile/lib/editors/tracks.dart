import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../music_library.dart';
import '../selectors/files.dart';
import '../selectors/recording.dart';
import '../widgets/recording_tile.dart';

class TrackModel {
  int workPartIndex;
  String workPartTitle;
  String fileName;

  TrackModel(this.fileName);
}

class TracksEditor extends StatefulWidget {
  @override
  _TracksEditorState createState() => _TracksEditorState();
}

class _TracksEditorState extends State<TracksEditor> {
  BackendState backend;
  WorkInfo workInfo;
  RecordingInfo recordingInfo;
  String parentId;
  List<TrackModel> trackModels = [];

  @override
  Widget build(BuildContext context) {
    backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tracks'),
        actions: <Widget>[
          FlatButton(
            child: Text('DONE'),
            onPressed: () async {
              final List<Track> tracks = [];

              for (var i = 0; i < trackModels.length; i++) {
                final trackModel = trackModels[i];

                tracks.add(Track(
                  fileName: trackModel.fileName,
                  recordingId: recordingInfo.recording.id,
                  index: i,
                  partIds: [trackModel.workPartIndex],
                ));
              }

              // We need to copy all information associated with this track we
              // got by asking the server to our local database. For now, we
              // will just override everything that we already had previously.
              backend.db.updateWork(workInfo);
              backend.db.updateRecording(recordingInfo);

              backend.ml.addTracks(parentId, tracks);

              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ReorderableListView(
        header: Column(
          children: <Widget>[
            ListTile(
              title: recordingInfo != null
                  ? RecordingTile(
                      workInfo: workInfo,
                      recordingInfo: recordingInfo,
                    )
                  : Text('Select recording'),
              onTap: selectRecording,
            ),
            ListTile(
              title: Text('Files'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final FilesSelectorResult result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FilesSelector(),
                    ),
                  );

                  if (result != null) {
                    final List<TrackModel> newTrackModels = [];

                    for (final document in result.selection) {
                      newTrackModels.add(TrackModel(document.name));
                    }

                    setState(() {
                      parentId = result.parentId;
                      trackModels = newTrackModels;
                    });

                    if (recordingInfo != null) {
                      updateAutoParts();
                    }
                  }
                },
              ),
            ),
          ],
        ),
        children: trackModels
            .map((t) => ListTile(
                  key: Key(t.hashCode.toString()),
                  leading: const Icon(Icons.drag_handle),
                  title: Text(t.workPartTitle ?? 'Set work part'),
                  subtitle: Text(t.fileName),
                ))
            .toList(),
        onReorder: (i1, i2) {
          setState(() {
            final track = trackModels.removeAt(i1);
            final newIndex = i2 > i1 ? i2 - 1 : i2;
            trackModels.insert(newIndex, track);
          });
        },
      ),
    );
  }

  Future<void> selectRecording() async {
    final RecordingSelectorResult result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingSelector(),
      ),
    );

    if (result != null) {
      setState(() {
        workInfo = result.workInfo;
        recordingInfo = result.recordingInfo;
      });

      updateAutoParts();
    }
  }

  /// Automatically associate the tracks with work parts.
  Future<void> updateAutoParts() async {
    setState(() {
      for (var i = 0; i < trackModels.length; i++) {
        if (i >= workInfo.parts.length) {
          trackModels[i].workPartIndex = null;
          trackModels[i].workPartTitle = null;
        } else {
          trackModels[i].workPartIndex = workInfo.parts[i].work.partIndex;
          trackModels[i].workPartTitle = workInfo.parts[i].work.title;
        }
      }
    });
  }
}
