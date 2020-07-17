import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';

import '../backend.dart';

class EnsembleEditor extends StatefulWidget {
  final Ensemble ensemble;

  EnsembleEditor({
    this.ensemble,
  });

  @override
  _EnsembleEditorState createState() => _EnsembleEditorState();
}

class _EnsembleEditorState extends State<EnsembleEditor> {
  final nameController = TextEditingController();

  bool uploading = false;
  bool _sync = true;

  @override
  void initState() {
    super.initState();

    if (widget.ensemble != null) {
      nameController.text = widget.ensemble.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = MusicusBackend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ensemble'),
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

                    final ensemble = Ensemble(
                      id: widget.ensemble?.id ?? generateId(),
                      name: nameController.text,
                      sync: _sync,
                      synced: false,
                    );

                    final success = await backend.client.putEnsemble(ensemble);

                    setState(() {
                      uploading = false;
                    });

                    if (success) {
                      Navigator.pop(context, ensemble);
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
          SwitchListTile(
            title: Text('Synchronize changes'),
            subtitle: Text(_sync
                ? 'Publish changes on the server'
                : 'Keep changes private'),
            value: _sync,
            onChanged: (value) {
              setState(() {
                _sync = value;
              });
            },
          ),
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
