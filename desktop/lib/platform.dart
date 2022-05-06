import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:musicus_common/musicus_common.dart';
import 'package:path/path.dart' as p;

class MusicusDesktopPlatform extends MusicusPlatform {
  @override
  Future<String> chooseBasePath() async {
    return await FilePicker.platform.getDirectoryPath();
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
