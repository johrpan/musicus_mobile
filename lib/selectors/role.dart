import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../editors/role.dart';

class RoleSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select role'),
      ),
      body: StreamBuilder<List<Role>>(
        stream: backend.db.allRoles().watch(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                final role = snapshot.data[index];

                return ListTile(
                  title: Text(role.name),
                  onTap: () => Navigator.pop(context, role),
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
          final Role role = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoleEditor(),
                fullscreenDialog: true,
              ));

          if (role != null) {
            Navigator.pop(context, role);
          }
        },
      ),
    );
  }
}
