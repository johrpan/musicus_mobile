import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../screens/program.dart';

import 'play_pause_button.dart';

class PlayerBar extends StatefulWidget {
  @override
  _PlayerBarState createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> {
  MusicusBackendState _backend;
  StreamSubscription<String> _currentTrackSubscribtion;
  WorkInfo _workInfo;
  List<int> _partIds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _backend = MusicusBackend.of(context);

    _currentTrackSubscribtion?.cancel();
    _currentTrackSubscribtion =
        _backend.playback.currentTrack.listen((track) async {
      if (track != null) {
        _setTrack(await _backend.db.tracksById(track).getSingle());
      }
    });
  }

  Future<void> _setTrack(Track track) async {
    final recording =
        await _backend.db.recordingById(track.recording).getSingle();

    final workInfo = await _backend.db.getWork(recording.work);

    final partIds = track.workParts
        .split(',')
        .where((p) => p.isNotEmpty)
        .map((p) => int.parse(p))
        .toList();

    if (mounted) {
      setState(() {
        _workInfo = workInfo;
        _partIds = partIds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;

    if (_workInfo != null) {
      title = '${_workInfo.composer.firstName} ${_workInfo.composer.lastName}';

      final subtitleBuffer = StringBuffer(_workInfo.work.title);

      if (_partIds.isNotEmpty) {
        subtitleBuffer.write(': ');
        subtitleBuffer
            .write(_partIds.map((i) => _workInfo.parts[i].title).join(', '));
      }

      subtitle = subtitleBuffer.toString();
    } else {
      title = '...';
      subtitle = '...';
    }

    return BottomAppBar(
      child: InkWell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            StreamBuilder(
              stream: _backend.playback.normalizedPosition,
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
                      DefaultTextStyle.merge(
                        style: TextStyle(fontWeight: FontWeight.bold),
                        child: Text(title),
                      ),
                      Text(subtitle),
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

  @override
  void dispose() {
    super.dispose();
    _currentTrackSubscribtion?.cancel();
  }
}
