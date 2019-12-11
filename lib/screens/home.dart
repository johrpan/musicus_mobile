import 'package:flutter/material.dart';

import '../backend.dart';
import '../selectors/person.dart';
import '../selectors/instruments.dart';

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
          ListTile(
            title: Text('Select person'),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonsSelector(),
                  fullscreenDialog: true,
                )),
          ),
          ListTile(
            title: Text('Select instrument'),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InstrumentsSelector(),
                  fullscreenDialog: true,
                )),
          ),
        ],
      ),
    );
  }
}
