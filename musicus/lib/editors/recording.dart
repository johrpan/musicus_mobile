import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../selectors/performer.dart';
import '../selectors/work.dart';
import '../widgets/texts.dart';

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

  Work work;
  List<PerformanceModel> performances = [];

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
                work: work.id,
                comment: commentController.text,
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
              ? ListTile(
                title: WorkText(work.id),
                subtitle: ComposersText(work.id),
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
        ],
      ),
    );
  }
}
