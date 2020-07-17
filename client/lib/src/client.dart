import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'database.dart';
import 'info.dart';

/// Credentials for a Musicus account.
class MusicusAccountCredentials {
  /// The user's username.
  final String username;

  /// The user's password.
  final String password;

  MusicusAccountCredentials({
    this.username,
    this.password,
  });
}

/// Additional information on a Musicus account.
class MusicusAccountDetails {
  /// An optional email address.
  final String email;

  MusicusAccountDetails({
    this.email,
  });
}

/// A simple http client for the Musicus server.
class MusicusClient {
  /// URI scheme to use for the connection.
  ///
  /// This will be used as the scheme parameter when creating Uri objects.
  final String scheme;

  /// The host name of the Musicus server to connect to.
  ///
  /// This will be used as the host parameter when creating Uri objects.
  final String host;

  /// This will be used as the port parameter when creating Uri objects.
  final int port;

  /// Base path to the root location of the Musicus API.
  final String basePath;

  MusicusAccountCredentials _credentials;

  /// Account credentials for login.
  ///
  /// If this is null, unauthorized requests will fail.
  MusicusAccountCredentials get credentials => _credentials;
  set credentials(MusicusAccountCredentials credentials) {
    _credentials = credentials;
    _token = null;
  }

  final _client = http.Client();

  /// The last retrieved access token.
  ///
  /// If this is null, a new token should be retrieved using [login] if needed.
  String _token;

  MusicusClient({
    this.scheme = 'https',
    @required this.host,
    this.port = 443,
    this.basePath,
    MusicusAccountCredentials credentials,
  })  : assert(scheme != null),
        assert(port != null),
        assert(host != null),
        _credentials = credentials;

  /// Create an URI using member variables and parameters.
  Uri createUri({
    @required String path,
    Map<String, String> params,
  }) {
    return Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: basePath != null ? basePath + path : path,
      queryParameters: params,
    );
  }

  /// Create a new Musicus account.
  ///
  /// The email address is optional. This will return true, if the action was
  /// successful. In that case, the new credentials will automatically be
  /// stored as under [credentials] and used for subsequent requests.
  Future<bool> registerAccount({
    @required String username,
    @required String password,
    String email,
  }) async {
    final response = await _client.post(
      createUri(
        path: '/account/register',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
      }),
    );

    if (response.statusCode == HttpStatus.ok) {
      _credentials = MusicusAccountCredentials(
        username: username,
        password: password,
      );

      _token = null;

      return true;
    } else {
      return false;
    }
  }

  /// Get the current account details.
  Future<MusicusAccountDetails> getAccountDetails() async {
    assert(_credentials != null);

    final response = await _authorized(
      'GET',
      createUri(path: '/account/details'),
    );

    if (response.statusCode == HttpStatus.ok) {
      final json = jsonDecode(response.body);

      return MusicusAccountDetails(
        email: json['email'],
      );
    } else {
      return null;
    }
  }

  /// Change the account details for the currently used user account.
  ///
  /// If a parameter is null, it will not be changed. This will throw a
  /// [MusicusLoginFailedException] if the account doesn't exist or the old
  /// password was wrong.
  Future<void> updateAccount({
    String newEmail,
    String newPassword,
  }) async {
    assert(_credentials != null);

    final response = await _client.post(
      createUri(path: '/account/details'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _credentials.username,
        'password': _credentials.password,
        'newEmail': newEmail,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != HttpStatus.ok) {
      throw MusicusLoginFailedException();
    }
  }

  /// Delete the currently used Musicus account.
  ///
  /// This will throw a [MusicusLoginFailedException] if the user doesn't exist
  /// or the password was wrong.
  Future<void> deleteAccount() async {
    assert(_credentials != null);

    final response = await _client.post(
      createUri(path: '/account/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _credentials.username,
        'password': _credentials.password,
      }),
    );

    if (response.statusCode == HttpStatus.ok) {
      _credentials = null;
      _token = null;
    } else {
      throw MusicusLoginFailedException();
    }
  }

  /// Retrieve an access token for the current user.
  ///
  /// This will be called automatically, when the client calls a method that
  /// requires it. If the login failed, a [MusicusLoginFailedException] will be
  /// thrown.
  Future<void> login() async {
    assert(_credentials != null);

    final response = await _client.post(
      createUri(
        path: '/account/login',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': _credentials.username,
        'password': _credentials.password,
      }),
    );

    if (response.statusCode == HttpStatus.ok) {
      _token = response.body;
    } else {
      throw MusicusLoginFailedException();
    }
  }

  /// Make a request with authorization.
  ///
  /// This will ensure, that the request will be made with a valid
  /// authorization header. If [user] is null, this will throw a
  /// [MusicusNotLoggedInException]. If it is neccessary, this will login the
  /// user and throw a [MusicusLoginFailedException] if that failed. If the
  /// user is not authorized to perform the requested action, this will throw
  /// a [MusicusNotAuthorizedException].
  Future<http.Response> _authorized(String method, Uri uri,
      {Map<String, String> headers, String body}) async {
    if (_credentials != null) {
      Future<http.Response> _request() async {
        final request = http.Request(method, uri);

        if (headers != null) {
          request.headers.addAll(headers);
        }

        request.headers['Authorization'] = 'Bearer $_token';

        if (body != null) {
          request.body = body;
        }

        return await http.Response.fromStream(await _client.send(request));
      }

      http.Response response;

      if (_token != null) {
        response = await _request();
        if (response.statusCode == HttpStatus.unauthorized) {
          await login();
          response = await _request();
        }
      } else {
        await login();
        response = await _request();
      }

      if (response.statusCode == HttpStatus.forbidden) {
        throw MusicusNotAuthorizedException();
      } else {
        return response;
      }
    } else {
      throw MusicusNotLoggedInException();
    }
  }

  /// Get a list of persons.
  ///
  /// You can get another page using the [page] parameter. If a non empty
  /// [search] string is provided, the persons will get filtered based on that
  /// string.
  Future<List<Person>> getPersons([int page, String search]) async {
    final params = <String, String>{};

    if (page != null) {
      params['p'] = page.toString();
    }

    if (search != null) {
      params['s'] = search;
    }

    final response = await _client.get(createUri(
      path: '/persons',
      params: params,
    ));

    final json = jsonDecode(response.body);
    return json
        .map<Person>((j) => Person.fromJson(j).copyWith(
              sync: true,
              synced: true,
            ))
        .toList();
  }

  /// Get a person by ID.
  Future<Person> getPerson(int id) async {
    final response = await _client.get(createUri(
      path: '/persons/$id',
    ));

    final json = jsonDecode(response.body);
    return Person.fromJson(json).copyWith(
      sync: true,
      synced: true,
    );
  }

  /// Delete a person by ID.
  Future<void> deletePerson(int id) async {
    await _authorized(
      'DELETE',
      createUri(
        path: '/persons/$id',
      ),
    );
  }

  /// Create or update a person.
  ///
  /// Returns true, if the operation was successful.
  Future<bool> putPerson(Person person) async {
    final response = await _authorized(
      'PUT',
      createUri(
        path: '/persons/${person.id}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(person.toJson()),
    );

    return response.statusCode == HttpStatus.ok;
  }

  /// Get a list of instruments.
  ///
  /// You can get another page using the [page] parameter. If a non empty
  /// [search] string is provided, the results will get filtered based on that
  /// string.
  Future<List<Instrument>> getInstruments([int page, String search]) async {
    final params = <String, String>{};

    if (page != null) {
      params['p'] = page.toString();
    }

    if (search != null) {
      params['s'] = search;
    }

    final response = await _client.get(createUri(
      path: '/instruments',
      params: params,
    ));

    final json = jsonDecode(response.body);
    return json
        .map<Instrument>((j) => Instrument.fromJson(j).copyWith(
              sync: true,
              synced: true,
            ))
        .toList();
  }

  /// Get an instrument by ID.
  Future<Instrument> getInstrument(int id) async {
    final response = await _client.get(createUri(
      path: '/instruments/$id',
    ));

    final json = jsonDecode(response.body);
    return Instrument.fromJson(json).copyWith(
      sync: true,
      synced: true,
    );
  }

  /// Create or update an instrument.
  ///
  /// Returns true, if the operation was successful.
  Future<bool> putInstrument(Instrument instrument) async {
    final response = await _authorized(
      'PUT',
      createUri(
        path: '/instruments/${instrument.id}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(instrument.toJson()),
    );

    return response.statusCode == HttpStatus.ok;
  }

  /// Delete an instrument by ID.
  Future<void> deleteInstrument(int id) async {
    await _authorized(
      'DELETE',
      createUri(
        path: '/instruments/$id',
      ),
    );
  }

  /// Get a list of works written by the person with the ID [personId].
  ///
  /// You can get another page using the [page] parameter. If a non empty
  /// [search] string is provided, the results will get filtered based on that
  /// string.
  Future<List<WorkInfo>> getWorks(int personId,
      [int page, String search]) async {
    final params = <String, String>{};

    if (page != null) {
      params['p'] = page.toString();
    }

    if (search != null) {
      params['s'] = search;
    }

    final response = await _client.get(createUri(
      path: '/persons/$personId/works',
      params: params,
    ));

    final json = jsonDecode(response.body);
    return json.map<WorkInfo>((j) => WorkInfo.fromJson(j, sync: true)).toList();
  }

  /// Get a work by ID.
  Future<WorkInfo> getWork(int id) async {
    final response = await _client.get(createUri(
      path: '/works/$id',
    ));

    final json = jsonDecode(response.body);
    return WorkInfo.fromJson(json, sync: true);
  }

  /// Delete a work by ID.
  Future<void> deleteWork(int id) async {
    await _authorized(
      'DELETE',
      createUri(
        path: '/works/$id',
      ),
    );
  }

  /// Get a list of recordings of the work with the ID [workId].
  ///
  /// You can get another page using the [page] parameter.
  Future<List<RecordingInfo>> getRecordings(int workId, [int page]) async {
    final params = <String, String>{};

    if (page != null) {
      params['p'] = page.toString();
    }

    final response = await _client.get(createUri(
      path: '/works/$workId/recordings',
      params: params,
    ));

    final json = jsonDecode(response.body);
    return json
        .map<RecordingInfo>((j) => RecordingInfo.fromJson(j, sync: true))
        .toList();
  }

  /// Create or update a work.
  ///
  /// Returns true, if the operation was successful.
  Future<bool> putWork(WorkInfo workInfo) async {
    final response = await _authorized(
      'PUT',
      createUri(
        path: '/works/${workInfo.work.id}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(workInfo.toJson()),
    );

    return response.statusCode == HttpStatus.ok;
  }

  /// Get a list of ensembles.
  ///
  /// You can get another page using the [page] parameter. If a non empty
  /// [search] string is provided, the results will get filtered based on that
  /// string.
  Future<List<Ensemble>> getEnsembles([int page, String search]) async {
    final params = <String, String>{};

    if (page != null) {
      params['p'] = page.toString();
    }

    if (search != null) {
      params['s'] = search;
    }

    final response = await _client.get(createUri(
      path: '/ensembles',
      params: params,
    ));

    final json = jsonDecode(response.body);
    return json
        .map<Ensemble>((j) => Ensemble.fromJson(j).copyWith(
              sync: true,
              synced: true,
            ))
        .toList();
  }

  /// Get an ensemble by ID.
  Future<Ensemble> getEnsemble(int id) async {
    final response = await _client.get(createUri(
      path: '/ensembles/$id',
    ));

    final json = jsonDecode(response.body);
    return Ensemble.fromJson(json).copyWith(
      sync: true,
      synced: true,
    );
  }

  /// Create or update an ensemble.
  ///
  /// Returns true, if the operation was successful.
  Future<bool> putEnsemble(Ensemble ensemble) async {
    final response = await _authorized(
      'PUT',
      createUri(
        path: '/ensembles/${ensemble.id}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(ensemble.toJson()),
    );

    return response.statusCode == HttpStatus.ok;
  }

  /// Delete an ensemble by ID.
  Future<void> deleteEnsemble(int id) async {
    await _authorized(
      'DELETE',
      createUri(
        path: '/ensembles/$id',
      ),
    );
  }

  /// Get a recording by ID.
  Future<RecordingInfo> getRecording(int id) async {
    final response = await _client.get(createUri(
      path: '/recordings/$id',
    ));

    final json = jsonDecode(response.body);
    return RecordingInfo.fromJson(json, sync: true);
  }

  /// Create or update a recording.
  ///
  /// Returns true, if the operation was successful.
  Future<bool> putRecording(RecordingInfo recordingInfo) async {
    final response = await _authorized(
      'PUT',
      createUri(
        path: '/recordings/${recordingInfo.recording.id}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(recordingInfo.toJson()),
    );

    return response.statusCode == HttpStatus.ok;
  }

  /// Delete a recording by ID.
  Future<void> deleteRecording(int id) async {
    await _authorized(
      'DELETE',
      createUri(
        path: '/recordings/$id',
      ),
    );
  }

  /// Close the internal http client.
  void dispose() {
    _client.close();
  }
}

class MusicusLoginFailedException implements Exception {
  MusicusLoginFailedException();

  String toString() => 'MusicusLoginFailedException: The username or password '
      'was wrong.';
}

class MusicusNotLoggedInException implements Exception {
  MusicusNotLoggedInException();

  String toString() =>
      'MusicusNotLoggedInException: The user must be logged in to perform '
      'this action.';
}

class MusicusNotAuthorizedException implements Exception {
  MusicusNotAuthorizedException();

  String toString() =>
      'MusicusNotAuthorizedException: The logged in user is not allowed to '
      'perform this action.';
}
