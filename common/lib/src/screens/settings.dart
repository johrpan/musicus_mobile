import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musicus_client/musicus_client.dart';
import 'package:musicus_common/musicus_common.dart';

import '../backend.dart';

import 'account_settings.dart';
import 'server_settings.dart';

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
          StreamBuilder<MusicusServerSettings>(
            stream: settings.server,
            builder: (context, snapshot) {
              final s = snapshot.data;

              return ListTile(
                title: Text('Musicus server'),
                subtitle:
                    Text(s != null ? '${s.host}:${s.port}${s.apiPath}' : '...'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final MusicusServerSettings result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServerSettingsScreen(),
                    ),
                  );

                  if (result != null) {
                    settings.setServer(result);
                  }
                },
              );
            },
          ),
          StreamBuilder<MusicusAccountCredentials>(
            stream: settings.account,
            builder: (context, snapshot) {
              final credentials = snapshot.data;

              return ListTile(
                title: Text('Account settings'),
                subtitle: Text(
                    credentials != null ? credentials.username : 'No account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccountSettingsScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}