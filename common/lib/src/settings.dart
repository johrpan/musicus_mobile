import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

/// Interface for persisting settings.
///
/// The methods should return null, if there is no value associated with the
/// provided key.
abstract class MusicusSettingsStorage {
  Future<void> load();
  Future<int> getInt(String key);
  Future<String> getString(String key);
  Future<void> setInt(String key, int value);
  Future<void> setString(String key, String value);
}

/// Settings concerning the Musicus server to connect to.
///
/// We don't support setting a scheme here, because there may be password being
/// submitted in the future, so we default to HTTPS.
class MusicusServerSettings {
  /// Host to connect to, e.g. 'musicus.johrpan.de';
  final String host;

  /// Port to connect to.
  final int port;

  /// Path to the API.
  ///
  /// This can be either null or empty, if the API is at the root of the host.
  final String apiPath;

  MusicusServerSettings({
    @required this.host,
    @required this.port,
    @required this.apiPath,
  });
}

/// Manager for all settings that are persisted.
class MusicusSettings {
  static const defaultHost = 'musicus.johrpan.de';
  static const defaultPort = 443;
  static const defaultApiPath = '/api';

  /// The storage method to use.
  final MusicusSettingsStorage storage;

  /// A identifier for the base path of the music library.
  ///
  /// This could be a file path on destop systems or a tree URI in terms of the
  /// Android storage access framework.
  final musicLibraryPath = BehaviorSubject<String>();

  /// Create a settings instance.
  MusicusSettings(this.storage);

  /// Initialize the settings.
  Future<void> load() async {
    await storage.load();

    final path = await storage.getString('musicLibraryPath');
    if (path != null) {
      musicLibraryPath.add(path);
    }
  }

  /// Set a new music library path.
  ///
  /// This will persist the new value and update the stream.
  Future<void> setMusicLibraryPath(String path) async {
    await storage.setString('musicLibraryPath', path);
    musicLibraryPath.add(path);
  }

  /// Tidy up.
  void dispose() {
    musicLibraryPath.close();
  }
}
