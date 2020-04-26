import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

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

  @override
  void initState() {
    super.initState();

    if (widget.ensemble != null) {
      nameController.text = widget.ensemble.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

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
