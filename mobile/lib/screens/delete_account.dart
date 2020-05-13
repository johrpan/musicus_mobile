import 'package:flutter/material.dart';
import 'package:musicus_common/musicus_common.dart';

class DeleteAccountScreen extends StatefulWidget {
  @override
  _DeleteAccountScreenState createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete account'),
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

                    if (_passwordController.text ==
                        backend.settings.account.value.password) {
                      setState(() {
                        _loading = true;
                      });

                      await backend.client.deleteAccount();
                      await backend.settings.clearAccount();

                      setState(() {
                        _loading = false;
                      });

                      Navigator.pop(context);
                    } else {
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text('Wrong password'),
                      ));
                    }
                  },
                  child: Text('DELETE'),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 8.0,
            ),
            child: Text(
              'If you really want to delete your account, enter your password '
              'below.',
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
