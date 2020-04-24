import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../editors/tracks.dart';

import 'person.dart';
import 'settings.dart';

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
                child: Text('Add tracks'),
              ),
              PopupMenuItem(
                value: 2,
                child: Text('Settings'),
              ),
            ],
            onSelected: (selected) {
              if (selected == 0) {
                backend.player.start();
              } else if (selected == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TracksEditor(),
                    fullscreenDialog: true,
                  ),
                );
              } else if (selected == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(),
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonScreen(
                        person: person,
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
