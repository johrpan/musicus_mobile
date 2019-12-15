import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../editors/work.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Musicus'),
        actions: <Widget>[
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0,
                child: Text('Start player'),
              ),
              PopupMenuItem(
                value: 1,
                child: Text('Add work'),
              ),
            ],
            onSelected: (selected) {
              if (selected == 0) {
                backend.startPlayer();
              } else if (selected == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkEditor(),
                    fullscreenDialog: true,
                  ),
                );
              }
            },
          ),
        ],
      ),
      // For debugging purposes
      body: StreamBuilder<List<Person>>(
        stream: backend.db.allPersons().watch(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                final person = snapshot.data[index];
                return ListTile(
                  title: Text('${person.lastName}, ${person.firstName}'),
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
