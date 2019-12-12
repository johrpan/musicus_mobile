import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../selectors/instruments.dart';
import '../selectors/person.dart';

class WorkData {
  String title = '';
  Person composer;
  List<Instrument> instruments = [];
  List<WorkData> parts = [];
}

class WorkProperties extends StatelessWidget {
  final TextEditingController titleController;
  final Person composer;
  final List<Instrument> instruments;
  final void Function(Person) onComposerChanged;
  final void Function(List<Instrument>) onInstrumentsChanged;

  WorkProperties({
    @required this.titleController,
    @required this.composer,
    @required this.instruments,
    @required this.onComposerChanged,
    @required this.onInstrumentsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
              onComposerChanged(person);
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
                  builder: (context) => InstrumentsSelector(
                    selection: instruments,
                  ),
                  fullscreenDialog: true,
                ));

            if (selection != null) {
              onInstrumentsChanged(selection);
            }
          },
        ),
      ],
    );
  }
}

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
  final WorkData data = WorkData();

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
          if (data.composer != null) {
            setState(() {
              data.composer = person;
            });
          }
        }();
      }

      () async {
        final selection =
            await backend.db.instrumentsByWork(widget.work.id).get();

        // We don't want to override already selected instruments.
        if (data.instruments.isEmpty) {
          setState(() {
            data.instruments = selection;
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
          WorkProperties(
            titleController: titleController,
            composer: data.composer,
            instruments: data.instruments,
            onComposerChanged: (composer) {
              setState(() {
                data.composer = composer;
              });
            },
            onInstrumentsChanged: (instruments) {
              setState(() {
                data.instruments = instruments;
              });
            },
          ),
        ],
      ),
    );
  }
}
