import 'dart:async';

import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';

class EnsembleText extends StatelessWidget {
  final int ensembleId;

  EnsembleText(this.ensembleId);

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return StreamBuilder<Ensemble>(
      stream: backend.db.ensembleById(ensembleId).watchSingle(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(snapshot.data.name);
        } else {
          return Container();
        }
      },
    );
  }
}

class PersonText extends StatelessWidget {
  final int personId;

  PersonText(this.personId);

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return StreamBuilder<Person>(
      stream: backend.db.personById(personId).watchSingle(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text('${snapshot.data.firstName} ${snapshot.data.lastName}');
        } else {
          return Container();
        }
      },
    );
  }
}

class PerformancesText extends StatefulWidget {
  final int recordingId;

  PerformancesText(this.recordingId);

  @override
  _PerformancesTextState createState() => _PerformancesTextState();
}

class _PerformancesTextState extends State<PerformancesText> {
  BackendState backend;
  StreamSubscription<List<Performance>> performancesSubscription;
  String text = '...';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    performancesSubscription?.cancel();
    backend = Backend.of(context);

    performancesSubscription = backend.db
        .performancesByRecording(widget.recordingId)
        .watch()
        .listen((performances) async {
      final List<String> texts = [];

      for (final performance in performances) {
        final buffer = StringBuffer();

        if (performance.person != null) {
          final person =
              await backend.db.personById(performance.person).getSingle();
          buffer.write('${person.firstName} ${person.lastName}');
        } else if (performance.ensemble != null) {
          final ensemble =
              await backend.db.ensembleById(performance.ensemble).getSingle();
          buffer.write(ensemble.name);
        } else {
          buffer.write('Unknown');
        }

        if (performance.role != null) {
          final role =
              await backend.db.instrumentById(performance.role).getSingle();
          buffer.write(' (${role.name})');
        }

        texts.add(buffer.toString());
      }

      setState(() {
        text = texts.join(', ');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(text);
  }

  @override
  void dispose() {
    super.dispose();
    performancesSubscription?.cancel();
  }
}

class WorkText extends StatelessWidget {
  final int workId;

  WorkText(this.workId);

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return StreamBuilder<Work>(
      stream: backend.db.workById(workId).watchSingle(),
      builder: (context, snapshot) => Text(snapshot.data?.title ?? '...'),
    );
  }
}

class ComposersText extends StatelessWidget {
  final int workId;

  ComposersText(this.workId);

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return StreamBuilder<List<Person>>(
      stream: backend.db.composersByWork(workId).watch(),
      builder: (context, snapshot) => Text(snapshot.hasData
          ? snapshot.data.map((p) => '${p.firstName} ${p.lastName}').join(', ')
          : '...'),
    );
  }
}
