/// Object representing a document in Storage Access Framework terms.
class Document {
  /// Unique ID for the document.
  ///
  /// The platform implementation thould be able to get the content of the
  /// document based on this value.
  final String id;

  /// Name of the document (i.e. file name).
  final String name;

  /// Document ID of the parent document.
  final String parent;

  /// Whether this document represents a directory.
  final bool isDirectory;

  Document({
    this.id,
    this.name,
    this.parent,
    this.isDirectory,
  });

  // Use Map<dynamic, dynamic> here, as we get casting errors otherwise. This
  // won't be typesafe anyway.
  Document.fromJson(Map<dynamic, dynamic> json)
      : id = json['id'],
        name = json['name'],
        parent = json['parent'],
        isDirectory = json['isDirectory'];
}

/// Platform dependent code for the Musicus backend.
abstract class MusicusPlatform {
  /// An identifier for the root directory of the music library.
  ///
  /// This will be the string, that is stored as musicLibraryPath in the
  /// settings object.
  String basePath;

  MusicusPlatform();

  /// This will be called, when the music library path was changed.
  void setBasePath(String path) {
    basePath = path;
  }

  /// Choose a root level directory for the music library.
  /// 
  /// This should return a string representation of the chosen directory
  /// suitable for storage as [basePath].
  Future<String> chooseBasePath();

  /// Get all documents in a directory.
  ///
  /// [parentId] will be the ID of the directory document. If [parentId] is
  /// null, the children of the root directory will be returned.
  Future<List<Document>> getChildren(String parentId);

  /// Read the contents of a document by ID.
  Future<String> readDocument(String id);

  /// Read from a document by name.
  /// 
  /// [parentId] is the document ID of the parent directory.
  Future<String> readDocumentByName(String parentId, String fileName);

  /// Get a string identifying a document.
  ///
  /// [parentId] is the document ID of the parent directory. The return value
  /// should be a string, that the playback object can use to find and play the
  /// file. It will be included in [InternalTrack] objects by the music
  /// library.
  Future<String> getIdentifier(String parentId, String fileName);

  /// Write to a document by name.
  ///
  /// [parentId] is the document ID of the parent directory.
  Future<void> writeDocumentByName(
      String parentId, String fileName, String contents);
}
