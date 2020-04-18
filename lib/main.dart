import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'backend.dart';

void main() {
  runApp(AudioServiceWidget(
    child: Backend(
      child: App(),
    ),
  ));
}
