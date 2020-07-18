import 'dart:io';

import 'package:file_chooser/file_chooser.dart';
import 'package:musicus_common/musicus_common.dart';
import 'package:path/path.dart' as p;

class MusicusDesktopPlatform extends MusicusPlatform {
  @override
  Future<String> chooseBasePath() async {
    final result = await showOpenPanel(
      canSelectDirectories: true,
    );

    if (result != null && !result.canceled) {
      return result.paths.first;
    } else {
      return null;
    }
  }

  @override
  Future<List<Document>> getChildren(String parentId) async {
    final List<Document> result = [];

    final parent = Directory(parentId ?? basePath);
    await for (final fse in parent.list()) {
      result.add(Document(
        id: fse.path,
        name: p.basename(fse.path),
        parent: parentId,
        isDirectory: fse is Directory,
      ));
    }

    return result;
  }

  @override
  Future<String> getIdentifier(String parentId, String fileName) async {
    return p.absolute(parentId, fileName);
  }

  @override
  Future<String> readDocument(String id) async {
    try {
      return await File(id).readAsString();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<String> readDocumentByName(String parentId, String fileName) async {
    try {
      return await File(p.absolute(parentId, fileName)).readAsString();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> writeDocumentByName(
      String parentId, String fileName, String contents) async {
    await File(p.absolute(parentId, fileName)).writeAsString(contents);
  }
}
