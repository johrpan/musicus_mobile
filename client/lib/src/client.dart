import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:musicus_database/musicus_database.dart';

/// A simple http client for the Musicus server.
class MusicusClient {
  /// The URL of the Musicus server to connect to.
  final String host;

  final _client = http.Client();

  MusicusClient(this.host);

  /// Get a list of all available persons.
  Future<List<Person>> getPersons() async {
    final response = await _client.get('$host/persons');
    final json = jsonDecode(response.body);
    return json.map<Person>((j) => Person.fromJson(j)).toList();
  }

  /// Get a person by ID.
  Future<Person> getPerson(int id) async {
    final response = await _client.get('$host/persons/$id');
    final json = jsonDecode(response.body);
    return Person.fromJson(json);
  }

  /// Create or update a person.
  Future<void> putPerson(Person person) async {
    await _client.put(
      '$host/persons/${person.id}',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(person.toJson()),
    );
  }

  /// Get a list of all available instruments.
  Future<List<Instrument>> getInstruments() async {
    final response = await _client.get('$host/instruments');
    final json = jsonDecode(response.body);
    return json.map<Instrument>((j) => Instrument.fromJson(j)).toList();
  }

  /// Get an instrument by ID.
  Future<Instrument> getInstrument(int id) async {
    final response = await _client.get('$host/instruments/$id');
    final json = jsonDecode(response.body);
    return Instrument.fromJson(json);
  }

  /// Create or update an instrument.
  Future<void> putInstrument(Instrument instrument) async {
    await _client.put(
      '$host/instruments/${instrument.id}',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(instrument.toJson()),
    );
  }

  /// Get all works composed by the person with the ID [personId].
  Future<List<Work>> getWorks(int personId) async {
    final response = await _client.get('$host/persons/$personId/works');
    final json = jsonDecode(response.body);
    return json.map<Work>((j) => Work.fromJson(j)).toList();
  }

  /// Get a work by ID.
  Future<Work> getWork(int id) async {
    final response = await _client.get('$host/works/$id');
    final json = jsonDecode(response.body);
    return Work.fromJson(json);
  }

  /// Get all work parts of the work with the ID [workId].
  Future<List<Work>> getParts(int workId) async {
    final response = await _client.get('$host/works/$workId/parts');
    final json = jsonDecode(response.body);
    return json.map<Work>((j) => Work.fromJson(j)).toList();
  }

  /// Get all recordings of the work with the ID [workId].
  Future<List<Recording>> getRecordings(int workId) async {
    final response = await _client.get('$host/works/$workId/recordings');
    final json = jsonDecode(response.body);
    return json.map<Recording>((j) => Recording.fromJson(j)).toList();
  }

  /// Create or update a work.
  Future<void> putWork(WorkData data) async {
    await _client.put(
      '$host/works/${data.data.work.id}',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data.toJson()),
    );
  }

  /// Get a list of all ensembles.
  Future<List<Ensemble>> getEnsembles() async {
    final response = await _client.get('$host/ensembles');
    final json = jsonDecode(response.body);
    return json.map<Ensemble>((j) => Ensemble.fromJson(j)).toList();
  }

  /// Get an ensemble by ID.
  Future<Ensemble> getEnsemble(int id) async {
    final response = await _client.get('$host/ensembles/$id');
    final json = jsonDecode(response.body);
    return Ensemble.fromJson(json);
  }

  /// Create or update an ensemble.
  Future<void> putEnsemble(Ensemble ensemble) async {
    await _client.put(
      '$host/ensembles/${ensemble.id}',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(ensemble.toJson()),
    );
  }

  /// Get a recording by ID.
  Future<Recording> getRecording(int id) async {
    final response = await _client.get('$host/recordings/$id');
    final json = jsonDecode(response.body);
    return Recording.fromJson(json);
  }

  /// Get all performances within the recording with the ID [recordingId].
  Future<List<Performance>> getPerformances(int recordingId) async {
    final response =
        await _client.get('$host/recordings/$recordingId/performances');
    final json = jsonDecode(response.body);
    return json.map<Performance>((j) => Performance.fromJson(j)).toList();
  }

  /// Create or update a recording.
  Future<void> putRecording(RecordingData data) async {
    await _client.put(
      '$host/recordings/${data.recording.id}',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data.toJson()),
    );
  }

  /// Close the internal http client.
  void dispose() {
    _client.close();
  }
}
