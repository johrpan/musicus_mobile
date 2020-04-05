import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';

class WorkTile extends StatelessWidget {
  final int workId;
  final void Function() onTap;

  WorkTile({
    this.workId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return StreamBuilder<Work>(
      stream: backend.db.workById(workId).watchSingle(),
      builder: (context, snapshot) {
        final titleText = snapshot.data?.title ?? '...';

        return StreamBuilder<List<Person>>(
          stream: backend.db.composersByWork(workId).watch(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListTile(
                title: Text(titleText),
                subtitle: Text(snapshot.data
                    .map((p) => '${p.firstName} ${p.lastName}')
                    .join(', ')),
                onTap: onTap ?? null,
              );
            } else {
              return ListTile(
                title: Text(titleText),
                subtitle: Text('...'),
                onTap: onTap ?? null,
              );
            }
          },
        );
      },
    );
  }
}
