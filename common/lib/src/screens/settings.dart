import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../backend.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = MusicusBackend.of(context);
    final settings = backend.settings;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          StreamBuilder<String>(
            stream: settings.musicLibraryPath,
            builder: (context, snapshot) {
              return ListTile(
                title: Text('Music library path'),
                subtitle: Text(snapshot.data ?? 'Choose folder'),
                isThreeLine: snapshot.hasData,
                onTap: () async {
                  final uri = await FilePicker.platform.getDirectoryPath();

                  if (uri != null) {
                    settings.setMusicLibraryPath(uri);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
