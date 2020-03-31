import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../editors/person.dart';

import 'instruments.dart';

// TODO: Allow selecting and adding ensembles.
class PerformerSelector extends StatefulWidget {
  @override
  _PerformerSelectorState createState() => _PerformerSelectorState();
}

class _PerformerSelectorState extends State<PerformerSelector> {
  Instrument role;
  Person person;

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select performer'),
        actions: <Widget>[
          FlatButton(
            child: Text('DONE'),
            onPressed: () => Navigator.pop(
              context,
              PerformanceModel(
                person: person,
                role: role,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Material(
            elevation: 2.0,
            child: ListTile(
              title: Text('Instrument/Role'),
              subtitle:
                  Text(role != null ? role.name : 'Select instrument/role'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    role = null;
                  });
                },
              ),
              onTap: () async {
                final Instrument newRole = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InstrumentsSelector(),
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

                      return RadioListTile<Person>(
                          controlAffinity: ListTileControlAffinity.trailing,
                          title:
                              Text('${person.lastName}, ${person.firstName}'),
                          value: person,
                          groupValue: this.person,
                          onChanged: (newPerson) {
                            setState(() {
                              this.person = newPerson;
                            });
                          });
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
            setState(() {
              this.person = person;
            });
          }
        },
      ),
    );
  }
}
