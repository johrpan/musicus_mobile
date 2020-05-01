import 'dart:async';

import 'package:flutter/material.dart';

import '../backend.dart';
import '../settings.dart';

class ServerSettingsScreen extends StatefulWidget {
  @override
  _ServerSettingsScreenState createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final hostController = TextEditingController();
  final portController = TextEditingController();
  final basePathController = TextEditingController();

  BackendState backend;
  StreamSubscription<ServerSettings> serverSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = Backend.of(context);

    if (serverSubscription != null) {
      serverSubscription.cancel();
    }

    _settingsChanged(backend.settings.server.value);
    serverSubscription = backend.settings.server.listen((settings) {
      _settingsChanged(settings);
    });
  }

  void _settingsChanged(ServerSettings settings) {
    hostController.text = settings.host;
    portController.text = settings.port.toString();
    basePathController.text = settings.basePath;
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
              backend.settings.resetServerSettings();
            },
          ),
          FlatButton(
            onPressed: () async {
              await backend.settings.setServerSettings(ServerSettings(
                host: hostController.text,
                port: int.parse(portController.text),
                basePath: basePathController.text,
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
              controller: basePathController,
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
