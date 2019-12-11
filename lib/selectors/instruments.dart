import 'package:flutter/material.dart';

import '../backend.dart';
import '../database.dart';
import '../editors/instrument.dart';

class InstrumentsSelector extends StatefulWidget {
  @override
  _InstrumentsSelectorState createState() => _InstrumentsSelectorState();
}

class _InstrumentsSelectorState extends State<InstrumentsSelector> {
  Set<Instrument> selection = {};

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select instruments'),
        actions: <Widget>[
          FlatButton(
            child: Text('DONE'),
            onPressed: () => Navigator.pop(context, selection.toList()),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: backend.db.allInstruments().watch(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                final instrument = snapshot.data[index];

                return CheckboxListTile(
                  title: Text(instrument.name),
                  value: selection.contains(instrument),
                  checkColor: Colors.black,
                  onChanged: (selected) {
                    setState(() {
                      if (selected) {
                        selection.add(instrument);
                      } else {
                        selection.remove(instrument);
                      }
                    });
                  },
                );
              },
            );
          } else {
            return Container();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final Instrument instrument = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InstrumentEditor(),
                fullscreenDialog: true,
              ));
          
          if (instrument != null) {
            setState(() {
              selection.add(instrument);
            });
          }
        },
      ),
    );
  }
}
