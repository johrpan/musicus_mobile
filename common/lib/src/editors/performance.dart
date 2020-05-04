import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../selectors/ensemble.dart';
import '../selectors/instruments.dart';
import '../selectors/person.dart';

class PerformanceEditor extends StatefulWidget {
  final PerformanceInfo performanceInfo;

  PerformanceEditor({
    this.performanceInfo,
  });

  @override
  _PerformanceEditorState createState() => _PerformanceEditorState();
}

class _PerformanceEditorState extends State<PerformanceEditor> {
  Person person;
  Ensemble ensemble;
  Instrument role;

  @override
  void initState() {
    super.initState();

    if (widget.performanceInfo != null) {
      person = widget.performanceInfo.person;
      ensemble = widget.performanceInfo.ensemble;
      role = widget.performanceInfo.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit performer'),
        actions: <Widget>[
          FlatButton(
            child: Text('DONE'),
            onPressed: () => Navigator.pop(
              context,
              PerformanceInfo(
                person: person,
                ensemble: ensemble,
                role: role,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Person'),
            subtitle: Text(person != null
                ? '${person.firstName} ${person.lastName}'
                : 'Select person'),
            onTap: () async {
              final Person newPerson = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonsSelector(),
                  fullscreenDialog: true,
                ),
              );

              if (newPerson != null) {
                setState(() {
                  person = newPerson;
                  ensemble = null;
                });
              }
            },
          ),
          ListTile(
            title: Text('Ensemble'),
            subtitle: Text(ensemble?.name ?? 'Select ensemble'),
            onTap: () async {
              final Ensemble newEnsemble = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EnsembleSelector(),
                  fullscreenDialog: true,
                ),
              );

              if (newEnsemble != null) {
                setState(() {
                  ensemble = newEnsemble;
                  person = null;
                });
              }
            },
          ),
          ListTile(
            title: Text('Role'),
            subtitle: Text(role?.name ?? 'Select instrument/role'),
            trailing: role != null
                ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        role = null;
                      });
                    },
                  )
                : null,
            onTap: () async {
              final Instrument newRole = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InstrumentsSelector(),
                  fullscreenDialog: true,
                ),
              );

              if (newRole != null) {
                setState(() {
                  role = newRole;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
