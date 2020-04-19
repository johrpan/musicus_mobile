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
        ],
      ),
    );
  }
}
