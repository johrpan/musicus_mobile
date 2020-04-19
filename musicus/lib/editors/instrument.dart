import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';

class InstrumentEditor extends StatefulWidget {
  final Instrument instrument;

  InstrumentEditor({
    this.instrument,
  });

  @override
  _InstrumentEditorState createState() => _InstrumentEditorState();
}

class _InstrumentEditorState extends State<InstrumentEditor> {
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.instrument != null) {
      nameController.text = widget.instrument.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Instrument/Role'),
        actions: <Widget>[
          FlatButton(
            child: Text('DONE'),
            onPressed: () async {
              final instrument = Instrument(
                id: widget.instrument?.id ?? generateId(),
                name: nameController.text,
              );

              await backend.db.updateInstrument(instrument);
              Navigator.pop(context, instrument);
            },
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
