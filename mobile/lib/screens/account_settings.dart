import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';
import 'package:musicus_common/musicus_common.dart';

import 'delete_account.dart';
import 'email.dart';
import 'password.dart';
import 'register.dart';

class AccountSettingsScreen extends StatefulWidget {
  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  MusicusBackendState _backend;
  StreamSubscription<MusicusAccountCredentials> _accountSubscription;
  bool _loading = false;
  bool _loggedIn = false;
  String _username;
  String _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _backend = MusicusBackend.of(context);

    final credentials = _backend.settings.account.value;
    if (credentials != null) {
      _setCredentials(credentials);
      _getDetails();
    }

    _accountSubscription = _backend.settings.account.listen((credentials) {
      _setCredentials(credentials);
    });
  }

  Future<void> _setCredentials(MusicusAccountCredentials credentials) async {
    if (mounted) {
      if (credentials != null) {
        setState(() {
          _loggedIn = true;
          _username = credentials.username;
        });
      } else {
        setState(() {
          _loggedIn = false;
        });
      }
    }
  }

  Future<void> _getDetails() async {
    setState(() {
      _email = null;
    });

    final email = (await _backend.client.getAccountDetails()).email;

    if (mounted) {
      setState(() {
        _email = email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children;

    if (_loggedIn) {
      children = [
        Material(
          elevation: 2.0,
          child: ListTile(
            title: Text('Logged in as: $_username'),
          ),
        ),
        ListTile(
          title: Text('E-mail address'),
          subtitle: Text(
              _email != null ? _email.isNotEmpty ? _email : 'Not set' : '...'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailScreen(
                  email: _email,
                ),
              ),
            );

            _getDetails();
          },
        ),
        ListTile(
          title: Text('Change password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PasswordScreen(),
              ),
            );
          },
        ),
        ListTile(
          title: Text('Delete this account'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeleteAccountScreen(),
              ),
            );
          },
        ),
        ListTile(
          title: Text('Logout'),
          onTap: () async {
            await _backend.settings.clearAccount();
            Navigator.pop(context);
          },
        ),
      ];
    } else {
      children = [
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 8.0,
          ),
          child: Text(
            'Enter your Musicus account credentials:',
            style: Theme.of(context).textTheme.subtitle1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          child: TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'User name',
            ),
          ),
        ),
        SizedBox(
          height: 16.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
            ),
          ),
        ),
        SizedBox(
          height: 32.0,
        ),
        ListTile(
          title: Text('Create a new account'),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterScreen(
                  username: _usernameController.text,
                  password: _passwordController.text,
                ),
              ),
            );
          },
        ),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Musicus account'),
        actions: <Widget>[
          Builder(
            builder: (context) {
              if (_loggedIn) {
                return Container();
              } else if (_loading) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                      ),
                    ),
                  ),
                );
              } else {
                return FlatButton(
                  onPressed: () async {
                    setState(() {
                      _loading = true;
                    });

                    final credentials = MusicusAccountCredentials(
                      username: _usernameController.text,
                      password: _passwordController.text,
                    );

                    _backend.client.credentials = credentials;

                    try {
                      await _backend.client.login();
                      await _backend.settings.setAccount(credentials);
                      Navigator.pop(context);
                    } on MusicusLoginFailedException {
                      Scaffold.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Login failed'),
                        ),
                      );
                    }

                    setState(() {
                      _loading = false;
                    });
                  },
                  child: Text('LOGIN'),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: children,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _accountSubscription.cancel();
  }
}
