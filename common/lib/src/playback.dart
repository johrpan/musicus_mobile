import 'package:meta/meta.dart';
import 'package:musicus_common/musicus_common.dart';
import 'package:rxdart/rxdart.dart';

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
  final playlist = BehaviorSubject.seeded(<String>[]);

  /// Index of the currently played (or paused) track within the playlist.
  ///
  /// This will be zero, if the player is not active!
  final currentIndex = BehaviorSubject.seeded(0);

  /// The currently played track.
  ///
  /// This will be null, if there is no  current track.
  final currentTrack = BehaviorSubject<String>.seeded(null);

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
  Future<void> setup(MusicusLibrary library);

  /// Add a list of tracks to the players playlist.
  Future<void> addTracks(List<String> tracks);

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

  /// Update [position] and [normalizedPosition].
  ///
  /// Requires [duration] to be up to date
  void updatePosition(Duration pos) {
    position.add(pos);
    _setNormalizedPosition(pos.inMilliseconds / duration.value.inMilliseconds);
  }

  /// Update [position], [duration] and [normalizedPosition].
  void updateDuration(Duration dur) {
    duration.add(dur);
    _setNormalizedPosition(position.value.inMilliseconds / dur.inMilliseconds);
  }

  /// Update [normalizedPosition] ensuring its value is between 0.0 and 1.0.
  void _setNormalizedPosition(double value) {
    if (value <= 0.0) {
      normalizedPosition.add(0.0);
    } else if (value >= 1.0) {
      normalizedPosition.add(1.0);
    } else {
      normalizedPosition.add(value);
    }
  }

  /// Update [currentIndex] and [currentTrack].
  ///
  /// Requires [playlist] to be up to date.
  void updateCurrentTrack(int index) {
    currentIndex.add(index);

    if (playlist.value != null && index >= 0 && index < playlist.value.length) {
      currentTrack.add(playlist.value[index]);
    }
  }
}
