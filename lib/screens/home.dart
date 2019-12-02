import 'package:flutter/material.dart';

import '../backend.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Musicus'),
      ),
      // For debugging purposes
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Start player'),
            onTap: backend.startPlayer,
          ),
          ListTile(
            title: Text('Play/Pause'),
            onTap: backend.playPause,
          ),
        ],
      ),
    );
  }
}
