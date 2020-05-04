import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../editors/ensemble.dart';
import '../widgets/lists.dart';

/// A screen to select an ensemble.
///
/// If the user has selected one, it will be returned as an [Ensemble] object
/// using the navigator.
class EnsembleSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select ensemble'),
      ),
      body: EnsemblesList(
        onSelected: (ensemble) {
          Navigator.pop(context, ensemble);
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final Ensemble ensemble = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnsembleEditor(),
              fullscreenDialog: true,
            ),
          );

          if (ensemble != null) {
            Navigator.pop(context, ensemble);
          }
        },
      ),
    );
  }
}
