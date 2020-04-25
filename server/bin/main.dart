import 'package:aqueduct/aqueduct.dart';
import 'package:musicus_server/musicus_server.dart';

Future<void> main() async {
  final configFilePath = 'config.yaml';
  final config = MusicusServerConfiguration(configFilePath);

  final server = Application<MusicusServer>()
    ..options.configurationFilePath = configFilePath
    ..options.address = config.host
    ..options.port = config.port;

  await server.start(
    consoleLogging: true,
  );

  print('Database: ${config.dbPath ?? 'memory'}');
  print('Listening on ${config.host}:${config.port}');
}
