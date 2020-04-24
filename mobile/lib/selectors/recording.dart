import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../editors/recording.dart';
import '../widgets/texts.dart';
import '../widgets/works_by_composer.dart';

class PersonList extends StatelessWidget {
  final void Function(int personId) onSelect;

  PersonList({
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Column(
      children: <Widget>[
        Material(
          elevation: 2.0,
          child: ListTile(
            title: Text('Composers'),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Person>>(
            stream: backend.db.allPersons().watch(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    final person = snapshot.data[index];
                    return ListTile(
                      title: Text('${person.lastName}, ${person.firstName}'),
                      onTap: () => onSelect(person.id),
                    );
                  },
                );
              } else {
                return Container();
              }
            },
          ),
        ),
      ],
    );
  }
}

class WorkList extends StatelessWidget {
  final int composerId;
  final void Function(int workId) onSelect;

  WorkList({
    this.composerId,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Material(
          elevation: 2.0,
          child: ListTile(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: PersonText(composerId),
          ),
        ),
        Expanded(
          child: WorksByComposer(
            personId: composerId,
            onTap: (selectedWork) => onSelect(selectedWork.id),
          ),
        ),
      ],
    );
  }
}

class RecordingList extends StatelessWidget {
  final int workId;
  final void Function(Recording recording) onSelect;

  RecordingList({
    this.workId,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);
    return Column(
      children: <Widget>[
        Material(
          elevation: 2.0,
          child: ListTile(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: WorkText(workId),
            subtitle: ComposersText(workId),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Recording>>(
            stream: backend.db.recordingsByWork(workId).watch(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    final recording = snapshot.data[index];
                    return ListTile(
                      title: PerformancesText(recording.id),
                      onTap: () => onSelect(recording),
                    );
                  },
                );
              } else {
                return Container();
              }
            },
          ),
        ),
      ],
    );
  }
}

class RecordingsSelector extends StatefulWidget {
  @override
  _RecordingsSelectorState createState() => _RecordingsSelectorState();
}

class _RecordingsSelectorState extends State<RecordingsSelector> {
  final nestedNavigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // This exists to circumvent the nested navigator when selecting a
    // recording.
    void popUpperNavigator(Recording recording) {
      Navigator.pop(context, recording);
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
        body: Navigator(
          key: nestedNavigator,
          onGenerateRoute: (settings) => settings.name == '/'
              ? MaterialPageRoute(
                  builder: (context) => PersonList(
                    onSelect: (personId) => nestedNavigator.currentState.push(
                      MaterialPageRoute(
                        builder: (context) => WorkList(
                          composerId: personId,
                          onSelect: (workId) =>
                              nestedNavigator.currentState.push(
                            MaterialPageRoute(
                              builder: (context) => RecordingList(
                                workId: workId,
                                onSelect: (recording) =>
                                    popUpperNavigator(recording),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          initialRoute: '/',
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
      onWillPop: () async => !(await nestedNavigator.currentState.maybePop()),
    );
  }
}
