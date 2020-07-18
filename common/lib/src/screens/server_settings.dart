import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musicus_common/musicus_common.dart';

import '../backend.dart';

class ServerSettingsScreen extends StatefulWidget {
  @override
  _ServerSettingsScreenState createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final hostController = TextEditingController();
  final portController = TextEditingController();
  final apiPathController = TextEditingController();

  MusicusBackendState backend;
  StreamSubscription<MusicusServerSettings> serverSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = MusicusBackend.of(context);

    if (serverSubscription != null) {
      serverSubscription.cancel();
    }

    _settingsChanged(backend.settings.server.value);
    serverSubscription = backend.settings.server.listen((settings) {
      _settingsChanged(settings);
    });
  }

  void _settingsChanged(MusicusServerSettings settings) {
    hostController.text = settings.host;
    portController.text = settings.port.toString();
    apiPathController.text = settings.apiPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Server settings'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to default',
            onPressed: () {
              backend.settings.resetServer();
            },
          ),
          FlatButton(
            onPressed: () async {
              await backend.settings.setServer(MusicusServerSettings(
                host: hostController.text,
                port: int.parse(portController.text),
                apiPath: apiPathController.text,
              ));

              Navigator.pop(context);
            },
            child: Text('DONE'),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: hostController,
              decoration: InputDecoration(
                labelText: 'Host',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Port',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: apiPathController,
              decoration: InputDecoration(
                labelText: 'API path',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    serverSubscription.cancel();
  }
}
