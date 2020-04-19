import 'package:flutter/material.dart';

import '../backend.dart';
import '../screens/program.dart';

import 'play_pause_button.dart';

class PlayerBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return BottomAppBar(
      child: InkWell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            StreamBuilder(
              stream: backend.player.normalizedPosition,
              builder: (context, snapshot) => LinearProgressIndicator(
                value: snapshot.data,
              ),
            ),
            Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.keyboard_arrow_up),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Composer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Work: Movement'),
                    ],
                  ),
                ),
                PlayPauseButton(),
              ],
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProgramScreen(),
          ),
        ),
      ),
    );
  }
}
