import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musicus_common/musicus_common.dart';

import 'screens/home.dart';
import 'widgets/player_bar.dart';

class App extends StatelessWidget {
  static const _platform = MethodChannel('de.johrpan.musicus/platform');

  @override
  Widget build(BuildContext context) {
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
                      final uri =
                          await _platform.invokeMethod<String>('openTree');

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
