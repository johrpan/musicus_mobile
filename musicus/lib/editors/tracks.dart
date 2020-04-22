import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../music_library.dart';
import '../selectors/files.dart';
import '../selectors/recording.dart';
import '../widgets/recording_tile.dart';

class TrackModel {
  String fileName;

  TrackModel(this.fileName);
}

class TracksEditor extends StatefulWidget {
  @override
  _TracksEditorState createState() => _TracksEditorState();
}

class _TracksEditorState extends State<TracksEditor> {
  int recordingId;
  String parentId;
  List<TrackModel> trackModels = [];

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

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
                  recordingId: recordingId,
                  index: i,
                  partIds: [],
                ));
              }

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
              title: recordingId != null
                  ? RecordingTile(
                      recordingId: recordingId,
                    )
                  : Text('Select recording'),
              onTap: selectRecording,
            ),
            ListTile(
              title: Text('Files'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final FilesSelectorResult result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FilesSelector(),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      parentId = result.parentId;
                      for (final document in result.selection) {
                        trackModels.add(TrackModel(document.name));
                      }
                    });
                  }
                },
              ),
            ),
          ],
        ),
        children: trackModels
            .map((t) => ListTile(
                  key: Key(t.hashCode.toString()),
                  title: Text(t.fileName),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        trackModels.remove(t);
                      });
                    },
                  ),
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

  void selectRecording() async {
    final Recording recording = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingsSelector(),
      ),
    );

    if (recording != null) {
      setState(() {
        recordingId = recording.id;
      });
    }
  }
}
