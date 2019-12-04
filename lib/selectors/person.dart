import 'package:flutter/material.dart';

import '../backend.dart';

class PersonsSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select person'),
      ),
      body: StreamBuilder(
          stream: backend.db.allPersons().watch(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) {
                  final person = snapshot.data[index];

                  return ListTile(
                    title: Text('${person.lastName}, ${person.firstName}'),
                    onTap: () => Navigator.pop(context, person),
                  );
                },
              );
            } else {
              return Container();
            }
          }),
    );
  }
}
