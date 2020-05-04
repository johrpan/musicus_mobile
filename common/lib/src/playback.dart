import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'library.dart';

/// Base class for Musicus playback.
abstract class MusicusPlayback {
  /// Whether the player is active.
  ///
  /// This means, that there is at least one item in the queue and the playback
  /// service is ready to play.
  final active = BehaviorSubject.seeded(false);

  /// The current playlist.
  ///
  /// If the player is not active, this will be an empty list.
  final playlist = BehaviorSubject.seeded(<InternalTrack>[]);

  /// Index of the currently played (or paused) track within the playlist.
  ///
  /// This will be zero, if the player is not active!
  final currentIndex = BehaviorSubject.seeded(0);

  /// The currently played track.
  ///
  /// This will be null, if there is no  current track.
  final currentTrack = BehaviorSubject<InternalTrack>.seeded(null);

  /// Whether we are currently playing or not.
  ///
  /// This will be false, if the player is not active.
  final playing = BehaviorSubject.seeded(false);

  /// Current playback position.
  ///
  /// If the player is not active, this will default to zero.
  final position = BehaviorSubject.seeded(const Duration());

  /// Duration of the current track.
  ///
  /// If the player is not active, the duration will default to 1 s.
  final duration = BehaviorSubject.seeded(const Duration(seconds: 1));

  /// Playback position normalized to the range from zero to one.
  final normalizedPosition = BehaviorSubject.seeded(0.0);

  /// Initialize the player.
  /// 
  /// This will be called after the database was initialized.
  Future<void> setup();

  /// Add a list of tracks to the players playlist.
  Future<void> addTracks(List<InternalTrack> tracks);

  /// Remove the track at [index] from the playlist.
  Future<void> removeTrack(int index);

  /// Toggle whether the player is playing or paused.
  Future<void> playPause();

  /// Seek to [pos], which is a value between (and including) zero and one.
  Future<void> seekTo(double pos);

  /// Skip to the previous track in the playlist.
  Future<void> skipToPrevious();

  /// Play the next track in the playlist.
  Future<void> skipToNext();

  /// Switch to the track with the index [index] in the playlist.
  Future<void> skipTo(int index);

  /// Set all values to their default.
  void reset() {
    active.add(false);
    playlist.add([]);
    currentTrack.add(null);
    playing.add(false);
    position.add(const Duration());
    duration.add(const Duration(seconds: 1));
    normalizedPosition.add(0.0);
  }

  /// Tidy up.
  @mustCallSuper
  void dispose() {
    active.close();
    playlist.close();
    currentIndex.close();
    currentTrack.close();
    playing.close();
    position.close();
    duration.close();
    normalizedPosition.close();
  }
}