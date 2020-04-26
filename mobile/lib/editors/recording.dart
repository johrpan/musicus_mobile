import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../editors/performance.dart';
import '../selectors/recording.dart';
import '../selectors/work.dart';

/// Screen for editing a recording.
///
/// If the user has finished editing, the result will be returned using the
/// navigator as a [RecordingSelectorResult] object.
class RecordingEditor extends StatefulWidget {
  final Recording recording;

  RecordingEditor({
    this.recording,
  });

  @override
  _RecordingEditorState createState() => _RecordingEditorState();
}

class _RecordingEditorState extends State<RecordingEditor> {
  final commentController = TextEditingController();

  WorkInfo workInfo;
  List<PerformanceInfo> performanceInfos = [];

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
      final WorkInfo newWorkInfo = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkSelector(),
            fullscreenDialog: true,
          ));

      if (newWorkInfo != null) {
        setState(() {
          workInfo = newWorkInfo;
        });
      }
    }

    final List<Widget> performanceTiles = [];
    for (var i = 0; i < performanceInfos.length; i++) {
      final p = performanceInfos[i];

      performanceTiles.add(ListTile(
        title: Text(p.person != null
            ? '${p.person.firstName} ${p.person.lastName}'
            : p.ensemble.name),
        subtitle: p.role != null ? Text(p.role.name) : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            setState(() {
              performanceInfos.remove(p);
            });
          },
        ),
        onTap: () async {
          final PerformanceInfo performanceInfo = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PerformanceEditor(
                  performanceInfo: p,
                ),
                fullscreenDialog: true,
              ));

          if (performanceInfo != null) {
            setState(() {
              performanceInfos[i] = performanceInfo;
            });
          }
        },
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Recording'),
        actions: <Widget>[
          FlatButton(
            child: Text('DONE'),
            onPressed: () async {
              final recordingInfo = RecordingInfo(
                recording: Recording(
                  id: widget.recording?.id ?? generateId(),
                  work: workInfo.work.id,
                  comment: commentController.text,
                ),
                performances: performanceInfos,
              );

              await backend.client.putRecording(recordingInfo);

              Navigator.pop(
                context,
                RecordingSelectorResult(
                  workInfo: workInfo,
                  recordingInfo: recordingInfo,
                ),
              );
            },
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          workInfo != null
              ? ListTile(
                  title: Text(workInfo.work.title),
                  subtitle: Text(workInfo.composers
                      .map((p) => '${p.firstName} ${p.lastName}')
                      .join(', ')),
                  onTap: selectWork,
                )
              : ListTile(
                  title: Text('Work'),
                  subtitle: Text('Select work'),
                  onTap: selectWork,
                ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 0.0,
              bottom: 16.0,
            ),
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Comment',
              ),
            ),
          ),
          ListTile(
            title: Text('Performers'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final PerformanceInfo model = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PerformanceEditor(),
                      fullscreenDialog: true,
                    ));

                if (model != null) {
                  setState(() {
                    performanceInfos.add(model);
                  });
                }
              },
            ),
          ),
          ...performanceTiles,
        ],
      ),
    );
  }
}
