import 'package:flutter/material.dart';

import '../backend.dart';
import '../editors/work.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Musicus'),
        actions: <Widget>[
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0,
                child: Text('Start player'),
              ),
              PopupMenuItem(
                value: 1,
                child: Text('Add work'),
              ),
            ],
            onSelected: (selected) {
              if (selected == 0) {
                backend.startPlayer();
              } else if (selected == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkEditor(),
                    fullscreenDialog: true,
                  ),
                );
              }
            },
          ),
        ],
      ),
      // For debugging purposes
      body: Container(),
    );
  }
}
