import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';

import '../backend.dart';
import '../editors/work.dart';
import '../widgets/lists.dart';

import 'work.dart';

class PersonScreen extends StatefulWidget {
  final Person person;

  PersonScreen({
    this.person,
  });

  @override
  _PersonScreenState createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  String _search;

  @override
  Widget build(BuildContext context) {
    final backend = MusicusBackend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: (text) {
            setState(() {
              _search = text;
            });
          },
          decoration: InputDecoration.collapsed(
            hintText:
                'Works by ${widget.person.firstName} ${widget.person.lastName}',
          ),
        ),
      ),
      body: PagedListView<WorkInfo>(
        search: _search,
        fetch: (page, search) async {
          return await backend.db.getWorks(widget.person.id, page, search);
        },
        builder: (context, workInfo) => ListTile(
          title: Text(workInfo.work.title),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkScreen(
                workInfo: workInfo,
              ),
            ),
          ),
          onLongPress: () {
            showDialog(
              context: context,
              builder: (context) {
                return SimpleDialog(
                  children: <Widget>[
                    ListTile(
                      title: Text('Edit work'),
                      onTap: () async {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkEditor(
                              workInfo: workInfo,
                            ),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
