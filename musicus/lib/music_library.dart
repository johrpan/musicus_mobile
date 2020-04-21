import 'dart:convert';

import 'package:flutter/services.dart';

import 'platform.dart';

/// Bundles a [Track] with the URI of the audio file it represents.
///
/// The uri shouldn't be stored on disk, but will be used at runtime.
class InternalTrack {
  /// The represented track.
  final Track track;

  /// The URI of the represented audio file as retrieved from the SAF.
  final String uri;

  InternalTrack({
    this.track,
    this.uri,
  });

  factory InternalTrack.fromJson(Map<String, dynamic> json) => InternalTrack(
        track: Track.fromJson(json['track']),
        uri: json['uri'],
      );

  Map<String, dynamic> toJson() => {
        'track': track.toJson(),
        'uri': uri,
      };
}

/// Description of a concrete audio file.
///
/// This gets stored in the folder of the audio file and links the audio file
/// to a recording in the database.
class Track {
  /// The name of the file that contains the track's audio.
  ///
  /// This corresponds to a document ID in terms of the Android Storage Access
  /// Framework.
  final String fileName;

  /// Index within the list of tracks for the corresponding recording.
  final int index;

  /// Of which recording this track is a part of.
  final int recordingId;

  /// Which work parts of the recorded work are contained in this track.
  final List<int> partIds;

  Track({
    this.fileName,
    this.index,
    this.recordingId,
    this.partIds,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        fileName: json['fileName'],
        index: json['index'],
        recordingId: json['recording'],
        partIds: List.from(json['parts']),
      );

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'index': index,
        'recording': recordingId,
        'parts': partIds,
      };
}

/// Representation of all tracked audio files in one folder.
class MusicusFile {
  /// Current version of the Musicus file format.
  ///
  /// If incompatible changes are made, this will be increased by one.
  static const currentVersion = 0;

  /// Musicus file format version in use.
  ///
  /// This will be used in the future, if incompatible changes are made.
  final int version;

  /// List of [Track] objects.
  final List<Track> tracks;

  MusicusFile({
    this.version = currentVersion,
    List<Track> tracks,
  }) : tracks = tracks ?? [];

  factory MusicusFile.fromJson(Map<String, dynamic> json) => MusicusFile(
        version: json['version'],
        tracks: json['tracks']
            .map<Track>((trackJson) => Track.fromJson(trackJson))
            .toList(growable: true),
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'tracks': tracks.map((t) => t.toJson()).toList(),
      };
}

/// Manager for all available tracks and their representation on disk.
class MusicLibrary {
  static const platform = MethodChannel('de.johrpan.musicus/platform');

  /// URI of the music library folder.
  ///
  /// This is a tree URI in the terms of the Android Storage Access Framework.
  final String treeUri;

  /// Map of all available tracks by recording ID.
  ///
  /// These are [InternalTrack] objects to store the URI of the corresponding
  /// audio file alongside the real [Track] object.
  final Map<int, List<InternalTrack>> tracks = {};

  MusicLibrary(this.treeUri);

  /// Load all available tracks.
  ///
  /// This recursively searches through the whole music library, reads the
  /// content of all files called musicus.json and stores all track information
  /// that it found.
  Future<void> load() async {
    // TODO: Consider capping the recursion somewhere.
    Future<void> recurse([String parentId]) async {
      final children = await Platform.getChildren(treeUri, parentId);

      for (final child in children) {
        if (child.isDirectory) {
          recurse(child.id);
        } else if (child.name == 'musicus.json') {
          final content = await Platform.readFile(treeUri, child.id);
          final musicusFile = MusicusFile.fromJson(jsonDecode(content));
          for (final track in musicusFile.tracks) {
            _indexTrack(parentId, track);
          }
        }
      }
    }

    await recurse();
  }

  /// Add a list of new tracks to the music library.
  ///
  /// They are stored in this instance and on disk in the directory denoted by
  /// [parentId].
  Future<void> addTracks(String parentId, List<Track> newTracks) async {
    MusicusFile musicusFile;

    final oldContent =
        await Platform.readFileByName(treeUri, parentId, 'musicus.json');

    if (oldContent != null) {
      musicusFile = MusicusFile.fromJson(jsonDecode(oldContent));
    } else {
      musicusFile = MusicusFile();
    }

    for (final track in newTracks) {
      _indexTrack(parentId, track);
      musicusFile.tracks.add(track);
    }

    await Platform.writeFileByName(
        treeUri, parentId, 'musicus.json', jsonEncode(musicusFile.toJson()));
  }

  /// Add a track to the map of available tracks.
  Future<void> _indexTrack(String parentId, Track track) async {
    final iTrack = InternalTrack(
      track: track,
      uri: await Platform.getUriByName(treeUri, parentId, track.fileName),
    );

    if (tracks.containsKey(track.recordingId)) {
      tracks[track.recordingId].add(iTrack);
    } else {
      tracks[track.recordingId] = [iTrack];
    }
  }
}
