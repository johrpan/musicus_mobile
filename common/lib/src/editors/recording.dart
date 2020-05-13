import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../editors/performance.dart';
import '../selectors/recording.dart';
import '../selectors/work.dart';

/// Screen for editing a recording.
///
/// If the user has finished editing, the result will be returned using the
/// navigator as a [RecordingSelectorResult] object.
class RecordingEditor extends StatefulWidget {
  /// The recording to edit.
  ///
  /// If this is null, a new recording will be created.
  final RecordingInfo recordingInfo;

  RecordingEditor({
    this.recordingInfo,
  });

  @override
  _RecordingEditorState createState() => _RecordingEditorState();
}

class _RecordingEditorState extends State<RecordingEditor> {
  final _commentController = TextEditingController();

  MusicusBackendState _backend;
  bool _uploading = false;
  WorkInfo _workInfo;
  List<PerformanceInfo> _performanceInfos = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _backend = MusicusBackend.of(context);
    if (widget.recordingInfo != null &&
        _workInfo == null &&
        _performanceInfos.isEmpty) {
      _init();
    }
  }

  Future<void> _init() async {
    _workInfo = await _backend.db.getWork(widget.recordingInfo.recording.work);
    _performanceInfos = List.from(widget.recordingInfo.performances);

    setState(() {
      this._workInfo = _workInfo;
      this._performanceInfos = _performanceInfos;
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<void> selectWork() async {
      final WorkInfo newWorkInfo = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkSelector(),
            fullscreenDialog: true,
          ));

      if (newWorkInfo != null) {
        setState(() {
          _workInfo = newWorkInfo;
        });
      }
    }

    final List<Widget> performanceTiles = [];
    for (var i = 0; i < _performanceInfos.length; i++) {
      final p = _performanceInfos[i];

      performanceTiles.add(ListTile(
        title: Text(p.person != null
            ? '${p.person.firstName} ${p.person.lastName}'
            : p.ensemble.name),
        subtitle: p.role != null ? Text(p.role.name) : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            setState(() {
              _performanceInfos.remove(p);
            });
          },
        ),
        onTap: () async {
          final PerformanceInfo performanceInfo = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PerformanceEditor(
                  performanceInfo: p,
                ),
                fullscreenDialog: true,
              ));

          if (performanceInfo != null) {
            setState(() {
              _performanceInfos[i] = performanceInfo;
            });
          }
        },
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Recording'),
        actions: <Widget>[
          _uploading
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                      ),
                    ),
                  ),
                )
              : FlatButton(
                  child: Text('DONE'),
                  onPressed: () async {
                    setState(() {
                      _uploading = true;
                    });

                    final recordingInfo = RecordingInfo(
                      recording: Recording(
                        id: widget?.recordingInfo?.recording?.id ??
                            generateId(),
                        work: _workInfo.work.id,
                        comment: _commentController.text,
                      ),
                      performances: _performanceInfos,
                    );

                    final success =
                        await _backend.client.putRecording(recordingInfo);

                    setState(() {
                      _uploading = false;
                    });

                    if (success) {
                      Navigator.pop(
                        context,
                        RecordingSelectorResult(
                          workInfo: _workInfo,
                          recordingInfo: recordingInfo,
                        ),
                      );
                    } else {
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text('Failed to upload'),
                      ));
                    }
                  },
                ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          _workInfo != null
              ? ListTile(
                  title: Text(_workInfo.work.title),
                  subtitle: Text(_workInfo.composers
                      .map((p) => '${p.firstName} ${p.lastName}')
                      .join(', ')),
                  onTap: selectWork,
                )
              : ListTile(
                  title: Text('Work'),
                  subtitle: Text('Select work'),
                  onTap: selectWork,
                ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 0.0,
              bottom: 16.0,
            ),
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Comment',
              ),
            ),
          ),
          ListTile(
            title: Text('Performers'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final PerformanceInfo model = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PerformanceEditor(),
                      fullscreenDialog: true,
                    ));

                if (model != null) {
                  setState(() {
                    _performanceInfos.add(model);
                  });
                }
              },
            ),
          ),
          ...performanceTiles,
        ],
      ),
    );
  }
}
