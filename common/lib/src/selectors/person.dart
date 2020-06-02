import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';

import '../editors/person.dart';
import '../widgets/lists.dart';

/// A screen to select a person.
///
/// If the user has selected a person, it will be returned as a [Person] object
/// using the navigator.
class PersonsSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select person'),
      ),
      body: PersonsList(
        onSelected: (person) {
          Navigator.pop(context, person);
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final Person person = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonEditor(),
              fullscreenDialog: true,
            ),
          );

          if (person != null) {
            Navigator.pop(context, person);
          }
        },
      ),
    );
  }
}
