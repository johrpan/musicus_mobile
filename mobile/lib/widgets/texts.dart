import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';

/// A widget showing information on a list of performances.
class PerformancesText extends StatelessWidget {
  /// The information to show.
  final List<PerformanceInfo> performanceInfos;

  PerformancesText({
    this.performanceInfos,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> performanceTexts = [];

    for (final p in performanceInfos) {
      final buffer = StringBuffer();

      if (p.person != null) {
        buffer.write('${p.person.firstName} ${p.person.lastName}');
      } else if (p.ensemble != null) {
        buffer.write(p.ensemble.name);
      } else {
        buffer.write('Unknown');
      }

      if (p.role != null) {
        buffer.write(' (${p.role.name})');
      }

      performanceTexts.add(buffer.toString());
    }

    return Text(performanceTexts.join(', '));
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
