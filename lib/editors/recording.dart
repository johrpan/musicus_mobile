import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../selectors/performer.dart';
import '../selectors/work.dart';

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
        ],
      ),
    );
  }
}
