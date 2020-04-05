import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../editors/recording.dart';
import '../widgets/works_by_composer.dart';
import '../widgets/performance_row.dart';

class RecordingsSelector extends StatefulWidget {
  @override
  _RecordingsSelectorState createState() => _RecordingsSelectorState();
}

class _RecordingsSelectorState extends State<RecordingsSelector> {
  Person composer;
  Work work;

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    bool showBackButton;
    String titleText;
    Widget content;

    if (composer != null) {
      showBackButton = true;
      if (work != null) {
        titleText = work.title;
        content = StreamBuilder<List<Recording>>(
          stream: backend.db.recordingsByWork(work.id).watch(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) {
                  final recording = snapshot.data[index];
                  return ListTile(
                    title: StreamBuilder<List<Performance>>(
                      stream: backend.db
                          .performancesByRecording(recording.id)
                          .watch(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              for (final performance in snapshot.data)
                                PerformanceRow(performance),
                            ],
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context, recording);
                    },
                  );
                },
              );
            } else {
              return Container();
            }
          },
        );
      } else {
        titleText = '${composer.firstName} ${composer.lastName}';
        content = WorksByComposer(
          personId: composer.id,
          onTap: (selectedWork) {
            setState(() {
              work = selectedWork;
            });
          },
        );
      }
    } else {
      showBackButton = false;
      titleText = 'Composers';

      content = StreamBuilder<List<Person>>(
        stream: backend.db.allPersons().watch(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                final person = snapshot.data[index];
                return ListTile(
                  title: Text('${person.lastName}, ${person.firstName}'),
                  onTap: () {
                    setState(() {
                      composer = person;
                    });
                  },
                );
              },
            );
          } else {
            return Container();
          }
        },
      );
    }

    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Select recording'),
        ),
        body: Column(
          children: <Widget>[
            Material(
              elevation: 2.0,
              child: ListTile(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: showBackButton ? goBack : null,
                ),
                title: Text(titleText),
              ),
            ),
            Expanded(
              child: content,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            final recording = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordingEditor(),
                fullscreenDialog: true,
              ),
            );

            if (recording != null) {
              Navigator.pop(context, recording);
            }
          },
        ),
      ),
      onWillPop: () => Future.value(goBack()),
    );
  }

  bool goBack() {
    if (work != null) {
      setState(() {
        work = null;
      });

      return false;
    } else if (composer != null) {
      setState(() {
        composer = null;
      });

      return false;
    } else {
      return true;
    }
  }
}
