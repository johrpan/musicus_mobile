import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';

import 'person_text.dart';
import 'ensemble_text.dart';

class PerformanceRow extends StatelessWidget {
  final Performance performance;

  PerformanceRow(this.performance);

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Row(
      children: <Widget>[
        if (performance.person != null)
          PersonText(performance.person)
        else if (performance.ensemble != null)
          EnsembleText(performance.ensemble),
        if (performance.role != null) ...[
          SizedBox(
            width: 4.0,
          ),
          StreamBuilder<Instrument>(
            stream: backend.db.instrumentById(performance.role).watchSingle(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text('(${snapshot.data.name})');
              } else {
                return Container();
              }
            },
          ),
        ],
      ],
    );
  }
}
