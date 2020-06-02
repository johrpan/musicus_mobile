import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';

import 'texts.dart';

class RecordingTile extends StatelessWidget {
  final WorkInfo workInfo;
  final RecordingInfo recordingInfo;

  RecordingTile({
    this.workInfo,
    this.recordingInfo,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DefaultTextStyle(
            style: textTheme.subtitle1,
            child: Text(workInfo.composers
                .map((p) => '${p.firstName} ${p.lastName}')
                .join(', ')),
          ),
          DefaultTextStyle(
            style: textTheme.headline6,
            child: Text(workInfo.work.title),
          ),
          const SizedBox(
            height: 4.0,
          ),
          DefaultTextStyle(
            style: textTheme.bodyText1,
            child: PerformancesText(
              performanceInfos: recordingInfo.performances,
            ),
          ),
        ],
      ),
    );
  }
}
