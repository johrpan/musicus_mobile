import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../widgets/texts.dart';

/// A list of persons.
class PersonsList extends StatelessWidget {
  /// Called, when the user has selected a person.
  final void Function(Person person) onSelected;

  PersonsList({
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return FutureBuilder<List<Person>>(
      future: backend.client.getPersons(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data.length,
            itemBuilder: (context, index) {
              final person = snapshot.data[index];

              return ListTile(
                title: Text('${person.lastName}, ${person.firstName}'),
                onTap: () {
                  if (onSelected != null) {
                    onSelected(person);
                  }
                },
              );
            },
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

/// A list of ensembles.
class EnsemblesList extends StatelessWidget {
  /// Called, when the user has selected an ensemble.
  final void Function(Ensemble ensemble) onSelected;

  EnsemblesList({
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return FutureBuilder<List<Ensemble>>(
      future: backend.client.getEnsembles(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data.length,
            itemBuilder: (context, index) {
              final ensemble = snapshot.data[index];

              return ListTile(
                title: Text(ensemble.name),
                onTap: () {
                  if (onSelected != null) {
                    onSelected(ensemble);
                  }
                },
              );
            },
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

/// A list of works by one composer.
class WorksList extends StatelessWidget {
  /// The ID of the composer.
  final int personId;

  /// Called, when the user has selected a work.
  final void Function(WorkInfo workInfo) onSelected;

  WorksList({
    this.personId,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return FutureBuilder<List<WorkInfo>>(
      future: backend.client.getWorks(personId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data.length,
            itemBuilder: (context, index) {
              final workInfo = snapshot.data[index];

              return ListTile(
                title: Text(workInfo.work.title),
                onTap: () {
                  if (onSelected != null) {
                    onSelected(workInfo);
                  }
                },
              );
            },
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

/// A list of recordings of a work.
class RecordingsList extends StatelessWidget {
  /// The ID of the work.
  final int workId;

  /// Called, when the user has selected a recording.
  final void Function(RecordingInfo recordingInfo) onSelected;

  RecordingsList({
    this.workId,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return FutureBuilder<List<RecordingInfo>>(
      future: backend.client.getRecordings(workId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data.length,
            itemBuilder: (context, index) {
              final recordingInfo = snapshot.data[index];

              return ListTile(
                title: PerformancesText(
                  performanceInfos: recordingInfo.performances,
                ),
                onTap: () {
                  if (onSelected != null) {
                    onSelected(recordingInfo);
                  }
                },
              );
            },
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
