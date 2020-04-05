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
