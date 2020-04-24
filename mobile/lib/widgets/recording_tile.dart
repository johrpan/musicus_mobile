import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';

import 'texts.dart';

class RecordingTile extends StatelessWidget {
  final int recordingId;

  RecordingTile({
    this.recordingId,
  });

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<Recording>(
      stream: backend.db.recordingById(recordingId).watchSingle(),
      builder: (context, snapshot) => Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (snapshot.hasData) ...[
              DefaultTextStyle(
                style: textTheme.subtitle1,
                child: ComposersText(snapshot.data.work),
              ),
              DefaultTextStyle(
                style: textTheme.headline6,
                child: WorkText(snapshot.data.work),
              ),
            ],
            const SizedBox(
              height: 4.0,
            ),
            DefaultTextStyle(
              style: textTheme.bodyText1,
              child: PerformancesText(recordingId),
            ),
          ],
        ),
      ),
    );
  }
}
