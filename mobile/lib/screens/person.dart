import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../editors/person.dart';

import 'work.dart';

class PersonScreen extends StatelessWidget {
  final Person person;

  PersonScreen({
    this.person,
  });

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${person.firstName} ${person.lastName}'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonEditor(
                    person: person,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Work>>(
        stream: backend.db.worksByComposer(person.id).watch(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                final work = snapshot.data[index];
                return ListTile(
                  title: Text(work.title),
                  onTap: () async {
                    final workInfo = await backend.db.getWorkInfo(work);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkScreen(
                          workInfo: workInfo,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
