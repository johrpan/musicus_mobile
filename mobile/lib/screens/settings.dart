import 'package:flutter/material.dart';

import '../backend.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.library_music),
            title: Text('Music library path'),
            subtitle: Text(backend.musicLibraryUri),
            onTap: () {
              backend.chooseMusicLibraryUri();
            },
          ),
          StreamBuilder<String>(
            stream: backend.musicusServerUrl,
            builder: (context, snapshot) {
              return ListTile(
                leading: Icon(Icons.router),
                title: Text('Musicus server'),
                subtitle: Text(snapshot.data ?? 'Set server URL'),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        final controller = TextEditingController();

                        if (snapshot.data != null) {
                          controller.text = snapshot.data;
                        }

                        return AlertDialog(
                          title: Text('Musicus server'),
                          content: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Server URL',
                            ),
                          ),
                          actions: <Widget>[
                            FlatButton(
                              onPressed: () {
                                backend.setMusicusServer(controller.text);
                                Navigator.pop(context);
                              },
                              child: Text('SET'),
                            ),
                            FlatButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('CANCEL'),
                            ),
                          ],
                        );
                      });
                },
              );
            }
          ),
        ],
      ),
    );
  }
}
