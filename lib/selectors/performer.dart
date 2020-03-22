import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../editors/person.dart';
import '../selectors/role.dart';

class PerformanceModel {
  final Person person;
  final Role role;

  PerformanceModel({
    this.person,
    this.role,
  });
}

// TODO: Allow selecting and adding ensembles.
// TODO: Allow selecting instruments as roles.
class PerformerSelector extends StatefulWidget {
  @override
  _PerformerSelectorState createState() => _PerformerSelectorState();
}

class _PerformerSelectorState extends State<PerformerSelector> {
  Role role;

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select performer'),
      ),
      body: Column(
        children: <Widget>[
          Material(
            elevation: 2.0,
            child: ListTile(
              title: Text('Role'),
              subtitle:
                  Text(role != null ? role.name : 'Select role or instrument'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    role = null;
                  });
                },
              ),
              onTap: () async {
                final Role newRole = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoleSelector(),
                      fullscreenDialog: true,
                    ));

                if (newRole != null) {
                  setState(() {
                    role = newRole;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: backend.db.allPersons().watch(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, index) {
                      final person = snapshot.data[index];

                      return ListTile(
                        title: Text('${person.lastName}, ${person.firstName}'),
                        onTap: () => Navigator.pop(context, PerformanceModel(
                          person: person,
                          role: role,
                        )),
                      );
                    },
                  );
                } else {
                  return Container();
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final Person person = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonEditor(),
                fullscreenDialog: true,
              ));

          if (person != null) {
            Navigator.pop(context, person);
          }
        },
      ),
    );
  }
}
