import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:musicus_common/musicus_common.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as pp;

import 'settings.dart';
import 'platform.dart';
import 'playback.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await pp.getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'db.sqlite');

  runApp(AudioServiceWidget(
    child: MusicusApp(
      dbPath: dbPath,
      settingsStorage: SettingsStorage(),
      platform: MusicusAndroidPlatform(),
      playback: Playback(),
    ),
  ));
}
