import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';

import '../backend.dart';
import '../editors/person.dart';
import '../editors/tracks.dart';
import '../icons.dart';
import '../widgets/lists.dart';

import 'about.dart';
import 'person.dart';
import 'settings.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _search;

  @override
  Widget build(BuildContext context) {
    final backend = MusicusBackend.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: Icon(
          MusicusIcons.musicus,
          color: Colors.amber,
        ),
        title: TextField(
          autofocus: true,
          onChanged: (text) {
            setState(() {
              _search = text;
            });
          },
          decoration: InputDecoration.collapsed(
            hintText: 'Composers',
          ),
        ),
        actions: <Widget>[
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Text('Add tracks'),
              ),
              PopupMenuItem(
                value: 2,
                child: Text('Settings'),
              ),
              PopupMenuItem(
                value: 3,
                child: Text('About'),
              ),
            ],
            onSelected: (selected) {
              if (selected == 1) {
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
              } else if (selected == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AboutScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: PagedListView<Person>(
        search: _search,
        fetch: (page, search) async {
          return await backend.db.getPersons(page, search);
        },
        builder: (context, person) => ListTile(
          title: Text('${person.lastName}, ${person.firstName}'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonScreen(
                person: person,
              ),
            ),
          ),
          onLongPress: () {
            showDialog(
              context: context,
              builder: (context) {
                return SimpleDialog(
                  children: <Widget>[
                    ListTile(
                      title: Text('Edit person'),
                      onTap: () async {
                        Navigator.pushReplacement(
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
