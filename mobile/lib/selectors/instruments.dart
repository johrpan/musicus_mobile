import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../editors/instrument.dart';
import '../widgets/lists.dart';

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
  final _list = GlobalKey<PagedListViewState<Instrument>>();
  
  Set<Instrument> selection = {};
  String _search;

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
        title: Text(widget.multiple
            ? 'Select instruments/roles'
            : 'Select instrument/role'),
        actions: widget.multiple
            ? <Widget>[
                FlatButton(
                  child: Text('DONE'),
                  onPressed: () => Navigator.pop(context, selection.toList()),
                ),
              ]
            : null,
      ),
      body: Column(
        children: <Widget>[
          Material(
            elevation: 2.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: TextField(
                autofocus: true,
                onChanged: (text) {
                  setState(() {
                    _search = text;
                  });
                },
                decoration: InputDecoration.collapsed(
                  hintText: 'Search by name...',
                ),
              ),
            ),
          ),
          Expanded(
            child: PagedListView<Instrument>(
              key: _list,
              search: _search,
              fetch: (page, search) async {
                return await backend.client.getInstruments(page, search);
              },
              builder: (context, instrument) {
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
            ),
          ),
        ],
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

              // We need to rebuild the list view, because we added an item.
              _list.currentState.update();
            } else {
              Navigator.pop(context, instrument);
            }
          }
        },
      ),
    );
  }
}
