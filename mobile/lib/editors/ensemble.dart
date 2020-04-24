import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';

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
          FlatButton(
            child: Text('DONE'),
            onPressed: () async {
              final ensemble = Ensemble(
                id: widget.ensemble?.id ?? generateId(),
                name: nameController.text,
              );

              await backend.db.updateEnsemble(ensemble);
              Navigator.pop(context, ensemble);
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
