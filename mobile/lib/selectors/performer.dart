import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../editors/ensemble.dart';
import '../editors/person.dart';

import 'instruments.dart';

class PerformerSelector extends StatefulWidget {
  @override
  _PerformerSelectorState createState() => _PerformerSelectorState();
}

class _Selection {
  final bool isPerson;
  final Person person;
  final Ensemble ensemble;

  _Selection.person(this.person)
      : isPerson = true,
        ensemble = null;

  _Selection.ensemble(this.ensemble)
      : isPerson = false,
        person = null;
}

class _PerformerSelectorState extends State<PerformerSelector> {
  Instrument role;
  _Selection selection;

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
                person: selection?.person,
                ensemble: selection?.ensemble,
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
            child: ListView(
              children: <Widget>[
                StreamBuilder<List<Person>>(
                  stream: backend.db.allPersons().watch(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data.isNotEmpty) {
                      return ExpansionTile(
                        initiallyExpanded: true,
                        title: Text('Persons'),
                        children: snapshot.data
                            .map((person) => RadioListTile<Person>(
                                  title: Text(
                                      '${person.lastName}, ${person.firstName}'),
                                  value: person,
                                  groupValue: selection?.person,
                                  onChanged: (person) {
                                    setState(() {
                                      selection = _Selection.person(person);
                                    });
                                  },
                                ))
                            .toList(),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
                StreamBuilder<List<Ensemble>>(
                  stream: backend.db.allEnsembles().watch(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data.isNotEmpty) {
                      return ExpansionTile(
                        initiallyExpanded: true,
                        title: Text('Ensembles'),
                        children: snapshot.data
                            .map((ensemble) => RadioListTile<Ensemble>(
                                  title: Text(ensemble.name),
                                  value: ensemble,
                                  groupValue: selection?.ensemble,
                                  onChanged: (ensemble) {
                                    setState(() {
                                      selection = _Selection.ensemble(ensemble);
                                    });
                                  },
                                ))
                            .toList(),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text('Add person'),
                  onTap: () async {
                    final Person person = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonEditor(),
                          fullscreenDialog: true,
                        ));

                    if (person != null) {
                      setState(() {
                        selection = _Selection.person(person);
                      });
                    }

                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text('Add ensemble'),
                  onTap: () async {
                    final Ensemble ensemble = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EnsembleEditor(),
                          fullscreenDialog: true,
                        ));

                    if (ensemble != null) {
                      setState(() {
                        selection = _Selection.ensemble(ensemble);
                      });
                    }

                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
