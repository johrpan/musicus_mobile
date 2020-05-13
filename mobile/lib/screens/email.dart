import 'package:flutter/material.dart';
import 'package:musicus_common/musicus_common.dart';

class EmailScreen extends StatefulWidget {
  final String email;

  EmailScreen({
    this.email,
  });

  @override
  _EmailScreenState createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _emailController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    if (widget.email != null) {
      _emailController.text = widget.email;
    }
  }

  Future<void> _setEmail(String email) async {
    setState(() {
      _loading = true;
    });

    final backend = MusicusBackend.of(context);

    await backend.client.updateAccount(
      newEmail: email,
    );

    setState(() {
      _loading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('E-mail address'),
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
                  onPressed: () {
                    _setEmail(_emailController.text);
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
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-mail',
              ),
            ),
          ),
          ListTile(
            title: Text('Delete E-mail address'),
            onTap: () {
              _setEmail('');
            },
          ),
        ],
      ),
    );
  }
}
