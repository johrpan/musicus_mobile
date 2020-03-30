import 'package:flutter/material.dart';
import 'package:path/path.dart' as pth;

import '../backend.dart';
import '../database.dart';
import '../selectors/files.dart';
import '../selectors/performer.dart';
import '../selectors/work.dart';

class TrackModel {
  final String path;

  TrackModel({
    this.path,
  });
}

class RecordingEditor extends StatefulWidget {
  final Recording recording;

  RecordingEditor({
    this.recording,
  });

  @override
  _RecordingEditorState createState() => _RecordingEditorState();
}

class _RecordingEditorState extends State<RecordingEditor> {
  Work work;
  List<PerformanceModel> performances = [];
  List<TrackModel> tracks = [];

  @override
  void initState() {
    super.initState();

    if (widget.recording != null) {
      // TODO: Initialize.
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    Future<void> selectWork() async {
      final Work newWork = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkSelector(),
            fullscreenDialog: true,
          ));

      if (newWork != null) {
        setState(() {
          work = newWork;
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Recording'),
        actions: <Widget>[
          FlatButton(
            child: Text('DONE'),
            onPressed: () async {
              final recording = Recording(
                id: widget.recording?.id ?? generateId(),
                work: null,
              );

              await backend.db.updateRecording(recording, performances);
              Navigator.pop(context, recording);
            },
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          work != null
              ? StreamBuilder<List<Person>>(
                  stream: backend.db.composersByWork(work.id).watch(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListTile(
                        title: Text(work.title),
                        subtitle: Text(snapshot.data
                            .map((p) => '${p.firstName} ${p.lastName}')
                            .join(', ')),
                        onTap: selectWork,
                      );
                    } else {
                      return ListTile(
                        title: Text(work.title),
                        subtitle: Text('…'),
                        onTap: selectWork,
                      );
                    }
                  },
                )
              : ListTile(
                  title: Text('Work'),
                  subtitle: Text('Select work'),
                  onTap: selectWork,
                ),
          ListTile(
            title: Text('Performers'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final PerformanceModel model = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PerformerSelector(),
                      fullscreenDialog: true,
                    ));

                if (model != null) {
                  setState(() {
                    performances.add(model);
                  });
                }
              },
            ),
          ),
          for (final performance in performances)
            ListTile(
              title: Text(performance.person != null
                  ? '${performance.person.firstName} ${performance.person.lastName}'
                  : performance.ensemble.name),
              subtitle:
                  performance.role != null ? Text(performance.role.name) : null,
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    performances.remove(performance);
                  });
                },
              ),
            ),
          ListTile(
            title: Text('Tracks'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final paths = await Navigator.push<Set<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilesSelector(
                      baseDirectory: backend.musicLibraryPath,
                    ),
                    fullscreenDialog: true,
                  ),
                );

                if (paths != null) {
                  setState(() {
                    for (final path in paths) {
                      final relPath =
                          pth.relative(path, from: backend.musicLibraryPath);
                      tracks.add(TrackModel(
                        path: relPath,
                      ));
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
}
