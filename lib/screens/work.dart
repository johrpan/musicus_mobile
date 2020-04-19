import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../editors/work.dart';
import '../widgets/texts.dart';

class WorkScreen extends StatelessWidget {
  final Work work;

  WorkScreen({
    this.work,
  });

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(work.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkEditor(
                    work: work,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Recording>>(
        stream: backend.db.recordingsByWork(work.id).watch(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                final recording = snapshot.data[index];
                return ListTile(
                  title: PerformancesText(recording.id),
                  onTap: () async {
                    // TODO: Play recording.
                  },
                );
              },
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
