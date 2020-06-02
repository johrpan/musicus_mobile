import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';

/// A widget showing information on a list of performances.
class PerformancesText extends StatelessWidget {
  /// The information to show.
  final List<PerformanceInfo> performanceInfos;

  PerformancesText({
    this.performanceInfos,
  });

  @override
  Widget build(BuildContext context) {
    if (performanceInfos.isEmpty) {
      return Text('Unknown performers');
    } else {
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
}
