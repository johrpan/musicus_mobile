import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';

import '../backend.dart';

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

  bool uploading = false;

  @override
  void initState() {
    super.initState();

    if (widget.instrument != null) {
      nameController.text = widget.instrument.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = MusicusBackend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Instrument/Role'),
        actions: <Widget>[
          uploading
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                      ),
                    ),
                  ),
                )
              : FlatButton(
                  child: Text('DONE'),
                  onPressed: () async {
                    setState(() {
                      uploading = true;
                    });

                    final instrument = Instrument(
                      id: widget.instrument?.id ?? generateId(),
                      name: nameController.text,
                    );

                    final success =
                        await backend.client.putInstrument(instrument);

                    setState(() {
                      uploading = false;
                    });

                    if (success) {
                      Navigator.pop(context, instrument);
                    } else {
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text('Failed to upload'),
                      ));
                    }
                  },
                ),
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
