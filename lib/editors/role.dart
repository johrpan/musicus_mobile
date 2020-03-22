import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';

class RoleEditor extends StatefulWidget {
  final Role role;

  RoleEditor({
    this.role,
  });

  @override
  _RoleEditorState createState() => _RoleEditorState();
}

class _RoleEditorState extends State<RoleEditor> {
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.role != null) {
      nameController.text = widget.role.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Role'),
        actions: <Widget>[
          FlatButton(
            child: Text('DONE'),
            onPressed: () async {
              final role = Role(
                id: widget.role?.id ?? generateId(),
                name: nameController.text,
              );

              await backend.db.updateRole(role);
              Navigator.pop(context, role);
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
