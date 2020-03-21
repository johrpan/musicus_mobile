import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkScreen(
                        work: work,
                      ),
                    ),
                  ),
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
