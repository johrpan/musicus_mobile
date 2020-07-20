import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';

import '../backend.dart';
import '../library.dart';
import '../screens/program.dart';

import 'play_pause_button.dart';

class PlayerBar extends StatefulWidget {
  @override
  _PlayerBarState createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> {
  MusicusBackendState _backend;
  StreamSubscription<InternalTrack> _currentTrackSubscribtion;
  WorkInfo _workInfo;
  List<int> _partIds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _backend = MusicusBackend.of(context);

    _currentTrackSubscribtion?.cancel();
    _currentTrackSubscribtion = _backend.playback.currentTrack.listen((track) {
      if (track != null) {
        _setTrack(track.track);
      }
    });
  }

  Future<void> _setTrack(Track track) async {
    final recording =
        await _backend.db.recordingById(track.recordingId).getSingle();
    final workInfo = await _backend.db.getWork(recording.work);
    final partIds = track.partIds;

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
      title = _workInfo.composers
          .map((p) => '${p.firstName} ${p.lastName}')
          .join(', ');

      final subtitleBuffer = StringBuffer(_workInfo.work.title);

      if (_partIds.isNotEmpty) {
        subtitleBuffer.write(': ');

        final section = _workInfo.sections.lastWhere(
          (s) => s.beforePartIndex <= _partIds[0],
          orElse: () => null,
        );

        if (section != null) {
          subtitleBuffer.write(section.title);
          subtitleBuffer.write(': ');
        }

        subtitleBuffer.write(
            _partIds.map((i) => _workInfo.parts[i].part.title).join(', '));
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