import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';

import '../backend.dart';

/// A screen for creating a new Musicus account.
class RegisterScreen extends StatefulWidget {
  final String username;
  final String password;

  RegisterScreen({
    this.username,
    this.password,
  });

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    if (widget.username != null) {
      nameController.text = widget.username;
    }

    if (widget.password != null) {
      passwordController.text = widget.password;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = MusicusBackend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create account'),
        actions: <Widget>[
          Builder(
            builder: (context) {
              if (!_loading) {
                return FlatButton(
                  onPressed: () async {
                    if (_verify()) {
                      setState(() {
                        _loading = true;
                      });

                      final success = await backend.client.registerAccount(
                        username: nameController.text,
                        email: emailController.text,
                        password: passwordController.text,
                      );

                      setState(() {
                        _loading = false;
                      });

                      if (success) {
                        await backend.settings
                            .setAccount(MusicusAccountCredentials(
                          username: nameController.text,
                          password: passwordController.text,
                        ));

                        Navigator.pop(context);
                      } else {
                        Scaffold.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to create account'),
                          ),
                        );
                      }
                    } else {
                      Scaffold.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid inputs'),
                        ),
                      );
                    }
                  },
                  child: Text('REGISTER'),
                );
              } else {
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
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'User name',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'E-mail address (optional)',
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: repeatController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password (repeat)',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Check whether all requirements are met.
  bool _verify() {
    return nameController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        passwordController.text == repeatController.text;
  }
}
