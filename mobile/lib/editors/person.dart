import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';

class PersonEditor extends StatefulWidget {
  final Person person;

  PersonEditor({
    this.person,
  });

  @override
  _PersonEditorState createState() => _PersonEditorState();
}

class _PersonEditorState extends State<PersonEditor> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.person != null) {
      firstNameController.text = widget.person.firstName;
      lastNameController.text = widget.person.lastName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Person'),
        actions: <Widget>[
          FlatButton(
            child: Text('DONE'),
            onPressed: () async {
              final person = Person(
                id: widget.person?.id ?? generateId(),
                firstName: firstNameController.text,
                lastName: lastNameController.text,
              );

              await backend.db.updatePerson(person);
              Navigator.pop(context, person);
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: 'First name',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: 'Last name',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
