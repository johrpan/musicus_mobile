import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../editors/work.dart';

// TODO: Lazy load works and/or optimize queries.
class WorkSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select work'),
      ),
      body: StreamBuilder<List<Person>>(
        stream: backend.db.allPersons().watch(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                final person = snapshot.data[index];
                final title = Text('${person.lastName}, ${person.firstName}');
                return StreamBuilder<List<Work>>(
                  stream: backend.db.worksByComposer(person.id).watch(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data.isNotEmpty) {
                      return ExpansionTile(
                        title: title,
                        children: <Widget>[
                          for (final work in snapshot.data)
                            ListTile(
                              title: Text(work.title),
                              onTap: () => Navigator.pop(context, work),
                            ),
                        ],
                      );
                    } else {
                      return ListTile(
                        title: title,
                      );
                    }
                  },
                );
              },
            );
          } else {
            return Container();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final Work work = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkEditor(),
                fullscreenDialog: true,
              ));

          if (work != null) {
            Navigator.pop(context, work);
          }
        },
      ),
    );
  }
}
