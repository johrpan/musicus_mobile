import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../editors/recording.dart';
import '../widgets/lists.dart';

class RecordingSelectorResult {
  final WorkInfo workInfo;
  final RecordingInfo recordingInfo;

  RecordingSelectorResult({
    this.workInfo,
    this.recordingInfo,
  });
}

/// A screen to select a recording.
///
/// If the user has selected a recording, a [RecordingSelectorResult] containing
/// the selected recording and the recorded work will be returned using the
/// navigator.
class RecordingSelector extends StatefulWidget {
  @override
  _RecordingSelectorState createState() => _RecordingSelectorState();
}

class _RecordingSelectorState extends State<RecordingSelector> {
  Person person;
  WorkInfo workInfo;

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (person == null) {
      body = PersonsList(
        onSelected: (newPerson) {
          setState(() {
            person = newPerson;
          });
        },
      );
    } else if (workInfo == null) {
      body = WorksList(
        personId: person.id,
        onSelected: (newWorkInfo) {
          setState(() {
            workInfo = newWorkInfo;
          });
        },
      );
    } else {
      body = RecordingsList(
        workId: workInfo.work.id,
        onSelected: (recordingInfo) {
          Navigator.pop(
            context,
            RecordingSelectorResult(
              workInfo: workInfo,
              recordingInfo: recordingInfo,
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Select recording'),
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final RecordingSelectorResult result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordingEditor(),
              fullscreenDialog: true,
            ),
          );

          if (result != null) {
            Navigator.pop(context, result);
          }
        },
      ),
    );
  }
}
