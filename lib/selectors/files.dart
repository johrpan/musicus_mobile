import 'package:flutter/material.dart';

import '../backend.dart';
import '../platform.dart';

class FilesSelector extends StatefulWidget {
  @override
  _FilesSelectorState createState() => _FilesSelectorState();
}

class _FilesSelectorState extends State<FilesSelector> {
  BackendState backend;
  List<Document> history = [];
  List<Document> children = [];
  Set<String> selectedIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = Backend.of(context);
    loadChildren();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Choose files'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('DONE'),
              onPressed: () {
                Navigator.pop(context, selectedIds);
              },
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Material(
              elevation: 2.0,
              child: ListTile(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: history.isNotEmpty ? up : null,
                ),
                title: Text(
                    history.isNotEmpty ? history.last.name : 'Music library'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: children.length,
                itemBuilder: (context, index) {
                  final document = children[index];

                  if (document.isDirectory) {
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(document.name),
                      onTap: () {
                        setState(() {
                          history.add(document);
                        });
                        loadChildren();
                      },
                    );
                  } else {
                    return CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.trailing,
                      secondary: const Icon(Icons.insert_drive_file),
                      title: Text(document.name),
                      value: selectedIds.contains(document.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            selectedIds.add(document.id);
                          } else {
                            selectedIds.remove(document.id);
                          }
                        });
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      onWillPop: () => Future.value(up()),
    );
  }

  Future<void> loadChildren() async {
    setState(() {
      children = [];
    });

    final newChildren = await Platform.getChildren(
        backend.musicLibraryUri, history.isNotEmpty ? history.last.id : null);

    newChildren.sort((d1, d2) {
      if (d1.isDirectory != d2.isDirectory) {
        return d1.isDirectory ? -1 : 1;
      } else {
        return d1.name.compareTo(d2.name);
      }
    });

    setState(() {
      children = newChildren;
    });
  }

  bool up() {
    if (history.isNotEmpty) {
      setState(() {
        history.removeLast();
      });

      loadChildren();

      return false;
    } else {
      return true;
    }
  }
}
