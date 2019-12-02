import 'dart:async';

import 'package:flutter/material.dart';

import '../backend.dart';

class ProgramScreen extends StatefulWidget {
  @override
  _ProgramScreenState createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  Backend backend;
  StreamSubscription<double> positionSubscription;
  double position = 0.0;
  bool seeking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = Backend.of(context);

    if (positionSubscription != null) {
      positionSubscription.cancel();
    }

    positionSubscription = backend.position.listen((pos) {
      if (!seeking) {
        setState(() {
          position = pos;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Program'),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Slider(
              value: position,
              onChangeStart: (_) {
                seeking = true;
              },
              onChangeEnd: (pos) {
                seeking = false;
                backend.seekTo(pos);
              },
              onChanged: (pos) {
                setState(() {
                  position = pos;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    positionSubscription.cancel();
  }
}
