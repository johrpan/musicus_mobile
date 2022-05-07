import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'backend.dart';
import 'screens/home.dart';
import 'settings.dart';
import 'playback.dart';
import 'widgets/player_bar.dart';

/// The classical music player and organizer.
///
/// This widget is the cross platform abstraction for a whole Musicus app. The
/// properties should be implemented seperately for each platform.
class MusicusApp extends StatelessWidget {
  /// Path to the database file.
  final String dbPath;

  /// An object to persist the settings.
  final MusicusSettingsStorage settingsStorage;

  /// An object handling playback.
  final MusicusPlayback playback;

  MusicusApp({
    @required this.dbPath,
    @required this.settingsStorage,
    @required this.playback,
  });

  @override
  Widget build(BuildContext context) {
    return MusicusBackend(
      settingsStorage: settingsStorage,
      playback: playback,
      child: Builder(
        builder: (context) {
          final backend = MusicusBackend.of(context);

          return MaterialApp(
            title: 'Musicus',
            theme: ThemeData(
              brightness: Brightness.dark,
              accentColor: Colors.amber,
              textSelectionColor: Colors.grey[600],
              cursorColor: Colors.amber,
              textSelectionHandleColor: Colors.amber,
              toggleableActiveColor: Colors.amber,
              // Added for sliders and FABs. Not everything seems to obey this.
              colorScheme: ColorScheme.dark(
                primary: Colors.amber,
                secondary: Colors.amber,
              ),
              snackBarTheme: SnackBarThemeData(
                backgroundColor: Colors.grey[800],
                contentTextStyle: TextStyle(
                  color: Colors.white,
                ),
                behavior: SnackBarBehavior.floating,
              ),
              fontFamily: 'Libertinus Sans',
            ),
            home: Builder(
              builder: (context) {
                if (backend.status == MusicusBackendStatus.loading) {
                  return Material(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  );
                } else if (backend.status == MusicusBackendStatus.setup) {
                  return Material(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Choose the base path for\nyour music library.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        SizedBox(
                          height: 16.0,
                        ),
                        ListTile(
                          leading: const Icon(Icons.folder_open),
                          title: Text('Choose path'),
                          onTap: () async {
                            final uri = await FilePicker.platform.getDirectoryPath();
                            if (uri != null) {
                              backend.settings.setMusicLibraryPath(uri);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                } else {
                  return Content();
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class Content extends StatefulWidget {
  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> with SingleTickerProviderStateMixin {
  final nestedNavigator = GlobalKey<NavigatorState>();

  AnimationController playerBarAnimation;
  MusicusBackendState backend;
  StreamSubscription<bool> playerActiveSubscription;

  @override
  void initState() {
    super.initState();

    playerBarAnimation = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = MusicusBackend.of(context);
    playerBarAnimation.value = backend.playback.active.value ? 1.0 : 0.0;

    if (playerActiveSubscription != null) {
      playerActiveSubscription.cancel();
    }

    playerActiveSubscription = backend.playback.active.listen((active) =>
        active ? playerBarAnimation.forward() : playerBarAnimation.reverse());
  }

  @override
  Widget build(BuildContext context) {
    // The nested Navigator is for every screen from which the player bar at
    // the bottom should be accessible. The WillPopScope widget intercepts
    // taps on the system back button and redirects them to the nested
    // navigator.
    return WillPopScope(
      onWillPop: () async => !(await nestedNavigator.currentState.maybePop()),
      child: Scaffold(
        body: Navigator(
          key: nestedNavigator,
          onGenerateRoute: (settings) => settings.name == '/'
              ? MaterialPageRoute(
                  builder: (context) => HomeScreen(),
                )
              : null,
          initialRoute: '/',
        ),
        bottomNavigationBar: SizeTransition(
          sizeFactor: CurvedAnimation(
            curve: Curves.easeOut,
            parent: playerBarAnimation,
          ),
          axisAlignment: -1.0,
          child: PlayerBar(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    playerActiveSubscription.cancel();
  }
}
