import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../selectors/files.dart';
import '../selectors/recording.dart';
import '../widgets/recording_tile.dart';

class TrackModel {
  String path;

  TrackModel(this.path);
}

class TracksEditor extends StatefulWidget {
  @override
  _TracksEditorState createState() => _TracksEditorState();
}

class _TracksEditorState extends State<TracksEditor> {
  int recordingId;
  List<TrackModel> tracks = [];

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
              // TODO: Save tracks.
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          recordingId != null
              ? RecordingTile(
                  recordingId: recordingId,
                  onTap: selectRecording,
                )
              : ListTile(
                  title: Text('Select recording'),
                  onTap: selectRecording,
                ),
          ListTile(
            title: Text('Files'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final Set<String> paths = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilesSelector(
                      baseDirectory: backend.musicLibraryPath,
                    ),
                  ),
                );

                if (paths != null) {
                  setState(() {
                    for (final path in paths) {
                      tracks.add(TrackModel(path));
                    }
                  });
                }
              },
            ),
          ),
          for (final track in tracks)
            ListTile(
              title: Text(track.path),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    tracks.remove(track);
                  });
                },
              ),
            ),
        ],
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
