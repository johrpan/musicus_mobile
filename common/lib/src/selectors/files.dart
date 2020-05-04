import 'package:flutter/material.dart';

import '../backend.dart';
import '../platform.dart';

/// Result of the user's interaction with the files selector.
///
/// This will be given back when popping the navigator.
class FilesSelectorResult {
  /// Document ID of the parent directory of the selected files.
  ///
  /// This will be null, if they are in the toplevel directory.
  final String parentId;

  /// Selected files.
  final Set<Document> selection;

  FilesSelectorResult(this.parentId, this.selection);
}

/// A screen for selecting files.
///
/// This returns a [FilesSelectorResult] when pooping the navigator. If
/// [chooseDirectory] is true, the user will select a directory instead. In
/// that case, the document ID of the directory will be returned directly.
/// If that value is null, this means that the toplevel directory was selected.
class FilesSelector extends StatefulWidget {
  /// Choose a directory instead of multiple files.
  final bool chooseDirectory;

  FilesSelector({
    this.chooseDirectory = false,
  });

  @override
  _FilesSelectorState createState() => _FilesSelectorState();
}

class _FilesSelectorState extends State<FilesSelector> {
  MusicusBackendState backend;
  List<Document> history = [];
  List<Document> children = [];
  Set<Document> selection = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = MusicusBackend.of(context);
    loadChildren();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              widget.chooseDirectory ? 'Choose directory' : 'Choose files'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(widget.chooseDirectory ? 'SELECT' : 'DONE'),
              onPressed: () {
                final parentId = history.isNotEmpty ? history.last.id : null;

                Navigator.pop(
                  context,
                  widget.chooseDirectory
                      ? parentId
                      : FilesSelectorResult(parentId, selection),
                );
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
                      value: selection.contains(document),
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            selection.add(document);
                          } else {
                            selection.remove(document);
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

      // We reset the selection here, because the user should not be able to
      // select files from multiple directories for now.
      selection = {};
    });

    final newChildren = await backend.platform
        .getChildren(history.isNotEmpty ? history.last.id : null);

    newChildren.sort((d1, d2) {
      if (d1.isDirectory != d2.isDirectory) {
        return d1.isDirectory ? -1 : 1;
      } else {
        return d1.name.compareTo(d2.name);
      }
    });

    if (mounted) {
      setState(() {
        children = newChildren;
      });
    }
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
