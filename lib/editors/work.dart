import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../selectors/instruments.dart';
import '../selectors/person.dart';

class WorkEditor extends StatefulWidget {
  final Work work;

  WorkEditor({
    this.work,
  });

  @override
  _WorkEditorState createState() => _WorkEditorState();
}

class _WorkEditorState extends State<WorkEditor> {
  final titleController = TextEditingController();

  Backend backend;
  Person composer;
  List<Instrument> instruments = [];

  @override
  void initState() {
    super.initState();

    if (widget.work != null) {
      titleController.text = widget.work.title;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = Backend.of(context);

    if (widget.work != null) {
      if (widget.work.composer != null) {
        () async {
          final person =
              await backend.db.personById(widget.work.composer).getSingle();

          // We don't want to override a newly selected composer.
          if (composer != null) {
            setState(() {
              composer = person;
            });
          }
        }();
      }

      () async {
        final selection =
            await backend.db.instrumentsByWork(widget.work.id).get();

        // We don't want to override already selected instruments.
        if (instruments.isEmpty) {
          setState(() {
            instruments = selection;
          });
        }
      }();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Work'),
        actions: <Widget>[
          FlatButton(
            child: Text('DONE'),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
              ),
            ),
          ),
          ListTile(
            title: Text('Composer'),
            subtitle: Text(composer != null
                ? '${composer.firstName} ${composer.lastName}'
                : 'Select composer'),
            onTap: () async {
              final Person person = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PersonsSelector(),
                    fullscreenDialog: true,
                  ));

              if (person != null) {
                setState(() {
                  composer = person;
                });
              }
            },
          ),
          ListTile(
            title: Text('Instruments'),
            subtitle: Text(instruments.isNotEmpty
                ? instruments.map((i) => i.name).join(', ')
                : 'Select instruments'),
            onTap: () async {
              final List<Instrument> selection = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InstrumentsSelector(),
                    fullscreenDialog: true,
                  ));

              if (selection != null) {
                setState(() {
                  instruments = selection;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
