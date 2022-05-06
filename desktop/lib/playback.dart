import 'package:musicus_common/musicus_common.dart';
import 'package:musicus_database/musicus_database.dart';

class MusicusDesktopPlayback extends MusicusPlayback {
  @override
  Future<void> setup() async {}

  @override
  Future<void> addTracks(List<Track> tracks) async {
    final List<Track> newPlaylist = List.from(playlist.value);
    newPlaylist.addAll(tracks);
    playlist.add(newPlaylist);
    active.add(true);
  }

  @override
  Future<void> playPause() async {
    playing.add(!playing.value);
  }

  @override
  Future<void> removeTrack(int index) async {
    final List<Track> tracks = List.from(playlist.value);
    tracks.removeAt(index);
    playlist.add(tracks);
  }

  @override
  Future<void> seekTo(double pos) async {
    if (active.value && pos >= 0.0 && pos <= 1.0) {
      final durationMs = duration.value.inMilliseconds;
      updatePosition((pos * durationMs).floor());
    }
  }

  @override
  Future<void> skipTo(int index) async {
    updateCurrentTrack(index);
  }

  @override
  Future<void> skipToNext() async {
    final index = currentIndex.value;
    if (playlist.value.length > index + 1) {
      updateCurrentTrack(index + 1);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final index = currentIndex.value;
    if (index > 0) {
      updateCurrentTrack(index - 1);
    }
  }
}
