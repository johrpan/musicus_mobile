import 'package:flutter/services.dart';

class MusicusPlayer {
  final _channel = MethodChannel('de.johrpan.musicus_player/platform');

  MusicusPlayer() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) {
    // TODO: Implement.
  }
}
