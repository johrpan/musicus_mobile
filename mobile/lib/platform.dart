import 'package:flutter/services.dart';
import 'package:musicus_common/musicus_common.dart';

class MusicusAndroidPlatform extends MusicusPlatform {
  static const _platform = MethodChannel('de.johrpan.musicus/platform');

  @override
  Future<String> chooseBasePath() async {
    return await _platform.invokeMethod<String>('openTree');
  }

  @override
  Future<List<Document>> getChildren(String parentId) async {
    final List<Map<dynamic, dynamic>> childrenJson =
        await _platform.invokeListMethod(
      'getChildren',
      {
        'treeUri': basePath,
        'parentId': parentId,
      },
    );

    return childrenJson
        .map((childJson) => Document.fromJson(childJson))
        .toList();
  }

  @override
  Future<String> getIdentifier(String parentId, String fileName) async {
    return await _platform.invokeMethod(
      'getUriByName',
      {
        'treeUri': basePath,
        'parentId': parentId,
        'fileName': fileName,
      },
    );
  }

  @override
  Future<String> readDocument(String id) async {
    return await _platform.invokeMethod(
      'readFile',
      {
        'treeUri': basePath,
        'id': id,
      },
    );
  }

  @override
  Future<String> readDocumentByName(String parentId, String fileName) async {
    return await _platform.invokeMethod(
      'readFileByName',
      {
        'treeUri': basePath,
        'parentId': parentId,
        'fileName': fileName,
      },
    );
  }

  @override
  Future<void> writeDocumentByName(
      String parentId, String fileName, String contents) async {
    await _platform.invokeMethod(
      'writeFileByName',
      {
        'treeUri': basePath,
        'parentId': parentId,
        'fileName': fileName,
        'content': contents,
      },
    );
  }
}
