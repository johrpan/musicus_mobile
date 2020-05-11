import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musicus_common/musicus_common.dart';

import 'register.dart';

/// A screen for logging in using a Musicus account.
class AccountSettingsScreen extends StatefulWidget {
  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final nameController = TextEditingController();
  final passwordController = TextEditingController();

  MusicusBackendState backend;
  StreamSubscription<MusicusAccountSettings> accountSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = MusicusBackend.of(context);

    if (accountSubscription != null) {
      accountSubscription.cancel();
    }

    _settingsChanged(backend.settings.account.value);
    accountSubscription = backend.settings.account.listen((settings) {
      _settingsChanged(settings);
    });
  }

  void _settingsChanged(MusicusAccountSettings settings) {
    nameController.text = settings?.username ?? '';
    passwordController.text = settings?.password ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account settings'),
        actions: <Widget>[
          FlatButton(
            onPressed: () async {
              await backend.settings.setAccount(MusicusAccountSettings(
                username: nameController.text,
                password: passwordController.text,
              ));

              Navigator.pop(context);
            },
            child: Text('LOGIN'),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'User name',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
          ),
          ListTile(
            title: Text('Create a new account'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisterScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: Text('Don\'t use an account'),
            onTap: () {
              backend.settings.clearAccount();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    accountSubscription.cancel();
  }
}
