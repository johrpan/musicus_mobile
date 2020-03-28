import 'dart:async';

import 'package:flutter/material.dart';

import 'backend.dart';
import 'screens/home.dart';
import 'widgets/player_bar.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

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
        fontFamily: 'Libertinus Sans',
      ),
      home: Builder(
        builder: (context) {
          if (backend.status == BackendStatus.loading) {
            return Material(
              color: Theme.of(context).scaffoldBackgroundColor,
            );
          } else if (backend.status == BackendStatus.needsPermissions) {
            return Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Musicus needs permissions\nto access your files.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(
                    height: 16.0,
                  ),
                  ListTile(
                    leading: const Icon(Icons.done),
                    title: Text('Grant permissions'),
                    onTap: () {
                      backend.requestPermissions();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text('Open system\'s app settings'),
                    onTap: () {
                      backend.openAppSettings();
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
  BackendState backend;
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

    backend = Backend.of(context);
    playerBarAnimation.value = backend.playerActive.value ? 1.0 : 0.0;

    if (playerActiveSubscription != null) {
      playerActiveSubscription.cancel();
    }

    playerActiveSubscription = backend.playerActive.listen((active) =>
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
