import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';

import '../backend.dart';

class PasswordScreen extends StatefulWidget {
  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _repeatController = TextEditingController();

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change password'),
        actions: <Widget>[
          Builder(
            builder: (context) {
              if (_loading) {
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
                    final backend = MusicusBackend.of(context);
                    final password = _newPasswordController.text;

                    if (_oldPasswordController.text ==
                            backend.settings.account.value.password &&
                        password.isNotEmpty &&
                        password == _repeatController.text) {
                      setState(() {
                        _loading = true;
                      });

                      await backend.client.updateAccount(
                        newPassword: password,
                      );

                      await backend.settings
                          .setAccount(MusicusAccountCredentials(
                        username: backend.settings.account.value.username,
                        password: password,
                      ));

                      setState(() {
                        _loading = false;
                      });

                      Navigator.pop(context);
                    } else {
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text('Invalid inputs'),
                      ));
                    }
                  },
                  child: Text('DONE'),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Old password',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New password',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _repeatController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New password (repeat)',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
