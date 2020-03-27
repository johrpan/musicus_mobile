import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class FilesSelector extends StatefulWidget {
  @override
  _FilesSelectorState createState() => _FilesSelectorState();
}

class _FilesSelectorState extends State<FilesSelector> {
  static const platform = MethodChannel('de.johrpan.musicus/platform');

  List<Directory> storageRoots = [];
  List<Directory> directories = [];
  List<FileSystemEntity> contents = [];
  Set<String> selectedPaths = {};

  @override
  void initState() {
    super.initState();

    platform.invokeListMethod<String>('getStorageRoots').then((sr) {
      setState(() {
        storageRoots = sr.map((path) => Directory(path)).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (directories.isEmpty) {
      if (storageRoots != null) {
        body = ListView(
          children: storageRoots
              .map((dir) => ListTile(
                    leading: const Icon(Icons.storage),
                    title: Text(dir.path),
                    onTap: () {
                      setState(() {
                        directories.add(dir);
                      });

                      openDirectory(dir);
                    },
                  ))
              .toList(),
        );
      } else {
        body = Container();
      }
    } else {
      if (contents != null) {
        body = ListView(
          children: contents.map((fse) {
            Widget result;

            if (fse is Directory) {
              result = ListTile(
                leading: const Icon(Icons.folder),
                title: Text(path.basename(fse.path)),
                onTap: () {
                  setState(() {
                    directories.add(fse);
                  });

                  openDirectory(fse);
                },
              );
            } else if (fse is File) {
              result = CheckboxListTile(
                value: selectedPaths.contains(fse.path),
                secondary: Icon(Icons.insert_drive_file),
                title: Text(path.basename(fse.path)),
                onChanged: (selected) {
                  setState(() {
                    if (selected) {
                      selectedPaths.add(fse.path);
                    } else {
                      selectedPaths.remove(fse.path);
                    }
                  });
                },
              );
            }

            return result;
          }).toList(),
        );
      } else {
        body = Container();
      }
    }

    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Choose files'),
          actions: <Widget>[
            FlatButton(
              child: Text('DONE'),
              onPressed: () {
                Navigator.pop(context, selectedPaths);
              },
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Material(
              elevation: 2.0,
              child: ListTile(
                leading: directories.isNotEmpty ? IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: up,
                ) : null,
                title: Text(directories.isEmpty
                    ? 'Storage devices'
                    : directories.last.path),
              ),
            ),
            Expanded(
              child: body,
            ),
          ],
        ),
      ),
      onWillPop: () {
        if (directories.isNotEmpty) {
          up();
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
    );
  }

  Future<void> openDirectory(Directory directory) async {
    setState(() {
      contents.clear();
    });

    final fses = await directory.list().toList();
    fses.sort((fse1, fse2) {
      int compareBasenames() =>
          path.basename(fse1.path).compareTo(path.basename(fse2.path));

      if (fse1 is Directory) {
        if (fse2 is Directory) {
          return compareBasenames();
        } else {
          return -1;
        }
      } else if (fse2 is Directory) {
        return 1;
      } else {
        return compareBasenames();
      }
    });

    setState(() {
      contents = fses;
    });
  }

  void up() {
    if (directories.isNotEmpty) {
      setState(() {
        directories.removeLast();
      });

      if (directories.isNotEmpty) {
        openDirectory(directories.last);
      }
    }
  }
}
