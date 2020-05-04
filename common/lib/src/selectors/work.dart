import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../editors/work.dart';
import '../widgets/lists.dart';

/// A screen to select a work.
///
/// If the user has selected a work, a [WorkInfo] will be returned
/// using the navigator.
class WorkSelector extends StatefulWidget {
  @override
  _WorkSelectorState createState() => _WorkSelectorState();
}

class _WorkSelectorState extends State<WorkSelector> {
  Person person;

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
    } else {
      body = WorksList(
        personId: person.id,
        onSelected: (workInfo) {
          setState(() {
            Navigator.pop(context, workInfo);
          });
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Select work'),
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final WorkInfo workInfo = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkEditor(),
              fullscreenDialog: true,
            ),
          );

          if (workInfo != null) {
            Navigator.pop(context, workInfo);
          }
        },
      ),
    );
  }
}
