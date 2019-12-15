import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';

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
