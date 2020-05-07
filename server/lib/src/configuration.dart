import 'dart:io';

import 'package:aqueduct/aqueduct.dart';

class MusicusServerConfiguration extends Configuration {
  MusicusServerConfiguration(String fileName) : super.fromFile(File(fileName));

  String host;
  int port;
  String secret;

  @optionalConfiguration
  String dbPath;

  @optionalConfiguration
  String serverDbPath;
}