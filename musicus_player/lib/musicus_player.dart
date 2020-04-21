import 'package:flutter/services.dart';

/// A simple music player.
///
/// Give it an URI using [setUri] and it will start playing.
class MusicusPlayer {
  /// Called, when the player reaches the end of the audio file.
  final void Function() onComplete;

  final _channel = MethodChannel('de.johrpan.musicus_player/platform');

  /// Create a new player.
  ///
  /// This will do nothing, until [setUri] was called. If the player reaches
  /// the end of the current audio file, [onComplete] will be called.
  MusicusPlayer({
    this.onComplete,
  }) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onComplete' && onComplete != null) {
      onComplete();
    }
  }

  /// Set URI of the audio file to play.
  ///
  /// The player will always stop doing, what it did before, and start
  /// playing from the provided URI if possible. The return value is the
  /// duration of the new track in milliseconds.
  Future<int> setUri(String uri) async {
    return await _channel.invokeMethod('setUri', {'uri': uri});
  }

  /// Play from the current URI and resume playback if previously paused.
  Future<void> play() async {
    await _channel.invokeMethod('play');
  }

  /// Get the current playback position in milliseconds.
  Future<int> getPosition() async {
    return await _channel.invokeMethod('getPosition');
  }

  /// Seek to a new position, which should be provided in milliseconds.
  Future<void> seekTo(int positionMs) async {
    await _channel.invokeMethod('seekTo', {'positionMs': positionMs});
  }

  /// Pause playback.
  Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  /// Stop the player.
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }
}
