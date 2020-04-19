import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';

class WorksByComposer extends StatelessWidget {
  final int personId;
  final void Function(Work work) onTap;

  WorksByComposer({
    this.personId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return StreamBuilder<List<Work>>(
      stream: backend.db.worksByComposer(personId).watch(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data.length,
            itemBuilder: (context, index) {
              final work = snapshot.data[index];
              return ListTile(
                title: Text(work.title),
                onTap: () => onTap(work),
              );
            },
          );
        } else {
          return Container();
        }
      },
    );
  }
}
