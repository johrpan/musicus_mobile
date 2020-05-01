import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:musicus_database/musicus_database.dart';

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

  final _client = http.Client();

  MusicusClient({
    this.scheme = 'https',
    @required this.host,
    this.port = 443,
    this.basePath,
  })  : assert(scheme != null),
        assert(port != null),
        assert(host != null);

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
    return json.map<Person>((j) => Person.fromJson(j)).toList();
  }

  /// Get a person by ID.
  Future<Person> getPerson(int id) async {
    final response = await _client.get(createUri(
      path: '/persons/$id',
    ));

    final json = jsonDecode(response.body);
    return Person.fromJson(json);
  }

  /// Delete a person by ID.
  Future<void> deletePerson(int id) async {
    await _client.delete(createUri(
      path: '/persons/$id',
    ));
  }

  /// Create or update a person.
  ///
  /// Returns true, if the operation was successful.
  Future<bool> putPerson(Person person) async {
    try {
      final response = await _client.put(
        createUri(
          path: '/persons/${person.id}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(person.toJson()),
      );

      return response.statusCode == HttpStatus.ok;
    } on Exception {
      return false;
    }
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
    return json.map<Instrument>((j) => Instrument.fromJson(j)).toList();
  }

  /// Get an instrument by ID.
  Future<Instrument> getInstrument(int id) async {
    final response = await _client.get(createUri(
      path: '/instruments/$id',
    ));

    final json = jsonDecode(response.body);
    return Instrument.fromJson(json);
  }

  /// Create or update an instrument.
  ///
  /// Returns true, if the operation was successful.
  Future<bool> putInstrument(Instrument instrument) async {
    try {
      final response = await _client.put(
        createUri(
          path: '/instruments/${instrument.id}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(instrument.toJson()),
      );

      return response.statusCode == HttpStatus.ok;
    } on Exception {
      return false;
    }
  }

  /// Delete an instrument by ID.
  Future<void> deleteInstrument(int id) async {
    await _client.delete(createUri(
      path: '/instruments/$id',
    ));
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
    return json.map<WorkInfo>((j) => WorkInfo.fromJson(j)).toList();
  }

  /// Get a work by ID.
  Future<WorkInfo> getWork(int id) async {
    final response = await _client.get(createUri(
      path: '/works/$id',
    ));

    final json = jsonDecode(response.body);
    return WorkInfo.fromJson(json);
  }

  /// Delete a work by ID.
  Future<void> deleteWork(int id) async {
    await _client.delete(createUri(
      path: '/works/$id',
    ));
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
    return json.map<RecordingInfo>((j) => RecordingInfo.fromJson(j)).toList();
  }

  /// Create or update a work.
  ///
  /// Returns true, if the operation was successful.
  Future<bool> putWork(WorkInfo workInfo) async {
    try {
      final response = await _client.put(
        createUri(
          path: '/works/${workInfo.work.id}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(workInfo.toJson()),
      );

      return response.statusCode == HttpStatus.ok;
    } on Exception {
      return false;
    }
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
    return json.map<Ensemble>((j) => Ensemble.fromJson(j)).toList();
  }

  /// Get an ensemble by ID.
  Future<Ensemble> getEnsemble(int id) async {
    final response = await _client.get(createUri(
      path: '/ensembles/$id',
    ));

    final json = jsonDecode(response.body);
    return Ensemble.fromJson(json);
  }

  /// Create or update an ensemble.
  ///
  /// Returns true, if the operation was successful.
  Future<bool> putEnsemble(Ensemble ensemble) async {
    try {
      final response = await _client.put(
        createUri(
          path: '/ensembles/${ensemble.id}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ensemble.toJson()),
      );

      return response.statusCode == HttpStatus.ok;
    } on Exception {
      return false;
    }
  }

  /// Delete an ensemble by ID.
  Future<void> deleteEnsemble(int id) async {
    await _client.delete(createUri(
      path: '/ensembles/$id',
    ));
  }

  /// Get a recording by ID.
  Future<RecordingInfo> getRecording(int id) async {
    final response = await _client.get(createUri(
      path: '/recordings/$id',
    ));

    final json = jsonDecode(response.body);
    return RecordingInfo.fromJson(json);
  }

  /// Create or update a recording.
  ///
  /// Returns true, if the operation was successful.
  Future<bool> putRecording(RecordingInfo recordingInfo) async {
    try {
      final response = await _client.put(
        createUri(
          path: '/recordings/${recordingInfo.recording.id}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(recordingInfo.toJson()),
      );

      return response.statusCode == HttpStatus.ok;
    } on Exception {
      return false;
    }
  }

  /// Delete a recording by ID.
  Future<void> deleteRecording(int id) async {
    await _client.delete(createUri(
      path: '/recordings/$id',
    ));
  }

  /// Close the internal http client.
  void dispose() {
    _client.close();
  }
}
