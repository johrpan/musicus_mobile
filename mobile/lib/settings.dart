import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings concerning the Musicus server to connect to.
///
/// We don't support setting a scheme here, because there may be password being
/// submitted in the future, so we default to HTTPS.
class ServerSettings {
  static const defaultHost = 'musicus.johrpan.de';
  static const defaultPort = 1833;
  static const defaultBasePath = '/api';

  /// Host to connect to, e.g. 'musicus.johrpan.de';
  final String host;

  /// Port to connect to.
  final int port;

  /// Path to the API.
  ///
  /// This should be null, if the API is at the root of the host.
  final String basePath;

  ServerSettings({
    @required this.host,
    @required this.port,
    @required this.basePath,
  });
}

/// Manager for all settings that are persisted.
class Settings {
  static const defaultHost = 'musicus.johrpan.de';
  static const defaultPort = 443;
  static const defaultBasePath = '/api';

  static const _platform = MethodChannel('de.johrpan.musicus/platform');

  /// The tree storage access framework tree URI of the music library.
  final musicLibraryUri = BehaviorSubject<String>();

  /// Musicus server to connect to.
  final server = BehaviorSubject<ServerSettings>();

  SharedPreferences _shPref;

  /// Initialize the settings.
  Future<void> load() async {
    _shPref = await SharedPreferences.getInstance();

    final uri = _shPref.getString('musicLibraryUri');
    if (uri != null) {
      musicLibraryUri.add(uri);
    }

    final host = _shPref.getString('serverHost') ?? defaultHost;
    final port = _shPref.getInt('serverPort') ?? defaultPort;
    final basePath = _shPref.getString('serverBasePath') ?? defaultBasePath;

    server.add(ServerSettings(
      host: host,
      port: port,
      basePath: basePath,
    ));
  }

  /// Open the system picker to select a new music library URI.
  Future<void> chooseMusicLibraryUri() async {
    final uri = await _platform.invokeMethod<String>('openTree');

    if (uri != null) {
      musicLibraryUri.add(uri);
      await _shPref.setString('musicLibraryUri', uri);
    }
  }

  /// Change the Musicus server settings.
  Future<void> setServerSettings(ServerSettings settings) async {
    await _shPref.setString('serverHost', settings.host);
    await _shPref.setInt('serverPort', settings.port);
    await _shPref.setString('serverBasePath', settings.basePath);

    server.add(settings);
  }

  /// Reset the server settings to their defaults.
  Future<void> resetServerSettings() async {
    await setServerSettings(ServerSettings(
      host: defaultHost,
      port: defaultPort,
      basePath: defaultBasePath,
    ));
  }

  /// Tidy up.
  void dispose() {
    musicLibraryUri.close();
    server.close();
  }
}
