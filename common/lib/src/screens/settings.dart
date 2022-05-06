import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../backend.dart';

class SettingsScreen extends StatelessWidget {
  static const _platform = MethodChannel('de.johrpan.musicus/platform');

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
                  final uri = await backend.platform.chooseBasePath();

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
