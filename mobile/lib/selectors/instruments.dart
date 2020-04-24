import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../editors/instrument.dart';

class InstrumentsSelector extends StatefulWidget {
  final bool multiple;
  final List<Instrument> selection;

  InstrumentsSelector({
    this.multiple = false,
    this.selection,
  });

  @override
  _InstrumentsSelectorState createState() => _InstrumentsSelectorState();
}

class _InstrumentsSelectorState extends State<InstrumentsSelector> {
  Set<Instrument> selection = {};

  @override
  void initState() {
    super.initState();

    if (widget.selection != null) {
      selection = widget.selection.toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = Backend.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.multiple ? 'Select instruments/roles' : 'Select instrument/role'),
        actions: widget.multiple
            ? <Widget>[
                FlatButton(
                  child: Text('DONE'),
                  onPressed: () => Navigator.pop(context, selection.toList()),
                ),
              ]
            : null,
      ),
      body: StreamBuilder(
        stream: backend.db.allInstruments().watch(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, index) {
                final instrument = snapshot.data[index];

                if (widget.multiple) {
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
                } else {
                  return ListTile(
                    title: Text(instrument.name),
                    onTap: () => Navigator.pop(context, instrument),
                  );
                }
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
            if (widget.multiple) {
              setState(() {
                selection.add(instrument);
              });
            } else {
              Navigator.pop(context, instrument);
            }
          }
        },
      ),
    );
  }
}
