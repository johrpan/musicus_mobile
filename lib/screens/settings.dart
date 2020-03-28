import 'package:flutter/material.dart';

import '../backend.dart';
import '../selectors/files.dart';

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
            subtitle: Text(backend.musicLibraryPath),
            onTap: () async {
              final path = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => FilesSelector(
                    mode: FilesSelectorMode.directory,
                  ),
                  fullscreenDialog: true,
                ),
              );

              if (path != null) {
                backend.setMusicLibraryPath(path);
              }
            },
          ),
        ],
      ),
    );
  }
}
