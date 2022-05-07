import 'package:flutter/widgets.dart';
import 'package:musicus_common/musicus_common.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as pp;

import 'settings.dart';
import 'playback.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await pp.getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'db.sqlite');

  runApp(
    MusicusApp(
      dbPath: dbPath,
      settingsStorage: SettingsStorage(),
      playback: MusicusMobilePlayback(),
    ),
  );
}
