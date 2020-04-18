import 'package:flutter/services.dart';

/// Object representing a document in Storage Access Framework terms.
class Document {
  /// Unique document ID given by the SAF.
  final String id;

  /// Name of the document (i.e. file name).
  final String name;

  /// Document ID of the parent document.
  final String parent;

  /// Whether this document represents a directory.
  final bool isDirectory;

  // Use Map<dynamic, dynamic> here, as we get casting errors otherwise. This
  // won't be typesafe anyway.
  Document.fromJson(Map<dynamic, dynamic> json)
      : id = json['id'],
        name = json['name'],
        parent = json['parent'],
        isDirectory = json['isDirectory'];
}

/// Collection of methods that are implemented platform dependent.
class Platform {
  static const _platform = MethodChannel('de.johrpan.musicus/platform');

  /// Get child documents.
  ///
  /// [treeId] is the base URI as requested from the SAF.
  /// [parentId] is the document ID of the parent. If this is null, the children
  /// of the tree base will be returned.
  static Future<List<Document>> getChildren(
      String treeUri, String parentId) async {
    final List<Map<dynamic, dynamic>> childrenJson =
        await _platform.invokeListMethod(
      'getChildren',
      {
        'treeUri': treeUri,
        'parentId': parentId,
      },
    );

    return childrenJson
        .map((childJson) => Document.fromJson(childJson))
        .toList();
  }
}
