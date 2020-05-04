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

  bool uploading = false;

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
    final backend = MusicusBackend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Person'),
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

                    final person = Person(
                      id: widget.person?.id ?? generateId(),
                      firstName: firstNameController.text,
                      lastName: lastNameController.text,
                    );

                    final success = await backend.client.putPerson(person);

                    setState(() {
                      uploading = false;
                    });

                    if (success) {
                      Navigator.pop(context, person);
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
