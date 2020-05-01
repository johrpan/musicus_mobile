import 'package:flutter/material.dart';

import '../backend.dart';
import '../settings.dart';

import 'server_settings.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);
    final settings = backend.settings;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          StreamBuilder<String>(
              stream: settings.musicLibraryUri,
              builder: (context, snapshot) {
                return ListTile(
                  title: Text('Music library path'),
                  subtitle: Text(snapshot.data ?? 'Choose folder'),
                  isThreeLine: snapshot.hasData,
                  onTap: () {
                    settings.chooseMusicLibraryUri();
                  },
                );
              }),
          StreamBuilder<ServerSettings>(
              stream: settings.server,
              builder: (context, snapshot) {
                final s = snapshot.data;

                return ListTile(
                  title: Text('Musicus server'),
                  subtitle: Text(
                      s != null ? '${s.host}:${s.port}${s.basePath}' : '...'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final ServerSettings result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServerSettingsScreen(),
                      ),
                    );

                    if (result != null) {
                      settings.setServerSettings(result);
                    }
                  },
                );
              }),
        ],
      ),
    );
  }
}
