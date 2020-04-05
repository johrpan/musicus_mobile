import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';

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
