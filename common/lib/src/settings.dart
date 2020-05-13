import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:musicus_client/musicus_client.dart';
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

  /// Musicus server to connect to.
  final server = BehaviorSubject<MusicusServerSettings>();

  /// Credentials for the Musicus account to login as.
  final account = BehaviorSubject<MusicusAccountCredentials>();

  /// Create a settings instance.
  MusicusSettings(this.storage);

  /// Initialize the settings.
  Future<void> load() async {
    await storage.load();

    final path = await storage.getString('musicLibraryPath');
    if (path != null) {
      musicLibraryPath.add(path);
    }

    final host = await storage.getString('serverHost') ?? defaultHost;
    final port = await storage.getInt('serverPort') ?? defaultPort;
    final apiPath = await storage.getString('serverApiPath') ?? defaultApiPath;

    server.add(MusicusServerSettings(
      host: host,
      port: port,
      apiPath: apiPath,
    ));

    final username = await storage.getString('accountUsername');
    final passwordBase64 = await storage.getString('accountPassword');

    if (username != null) {
      account.add(MusicusAccountCredentials(
        username: username,
        password: utf8.decode(base64Decode(passwordBase64)),
      ));
    }
  }

  /// Set a new music library path.
  ///
  /// This will persist the new value and update the stream.
  Future<void> setMusicLibraryPath(String path) async {
    await storage.setString('musicLibraryPath', path);
    musicLibraryPath.add(path);
  }

  /// Update the server settings.
  ///
  /// This will persist the new values and update the stream.
  Future<void> setServer(MusicusServerSettings serverSettings) async {
    await storage.setString('serverHost', serverSettings.host);
    await storage.setInt('serverPort', serverSettings.port);
    await storage.setString('severApiPath', serverSettings.apiPath);
    server.add(serverSettings);
  }

  /// Reset the server settings to their defaults.
  Future<void> resetServer() async {
    await setServer(MusicusServerSettings(
      host: defaultHost,
      port: defaultPort,
      apiPath: defaultApiPath,
    ));
  }

  /// Update the account credentials.
  ///
  /// This will persist the new values and update the stream.
  Future<void> setAccount(MusicusAccountCredentials credentials) async {
    await storage.setString('accountUsername', credentials.username);

    // IMPORTANT NOTE: We encode the password using Base64 to defend just the
    // simplest of simplest attacks. This provides no additional security
    // besides the fact that the password looks a little bit encrypted.
    await storage.setString(
      'accountPassword',
      base64Encode(utf8.encode(credentials.password)),
    );

    account.add(credentials);
  }

  /// Delete the current account credentials.
  Future<void> clearAccount() async {
    await storage.setString('accountUsername', null);
    await storage.setString('accountPassword', null);

    account.add(null);
  }

  /// Tidy up.
  void dispose() {
    musicLibraryPath.close();
    server.close();
    account.close();
  }
}
