import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../selectors/instruments.dart';
import '../selectors/person.dart';

class PartData {
  final titleController = TextEditingController();

  Person composer;
  List<Instrument> instruments;

  PartData({
    String title,
    this.composer,
    this.instruments = const [],
  }) {
    titleController.text = title ?? '';
  }
}

class WorkProperties extends StatelessWidget {
  final TextEditingController titleController;
  final Person composer;
  final List<Instrument> instruments;
  final void Function(Person) onComposerChanged;
  final void Function(List<Instrument>) onInstrumentsChanged;

  WorkProperties({
    @required this.titleController,
    @required this.composer,
    @required this.instruments,
    @required this.onComposerChanged,
    @required this.onInstrumentsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'Title',
            ),
          ),
        ),
        ListTile(
          title: Text('Composer'),
          subtitle: Text(composer != null
              ? '${composer.firstName} ${composer.lastName}'
              : 'Select composer'),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              onComposerChanged(null);
            },
          ),
          onTap: () async {
            final Person person = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonsSelector(),
                  fullscreenDialog: true,
                ));

            if (person != null) {
              onComposerChanged(person);
            }
          },
        ),
        ListTile(
          title: Text('Instruments'),
          subtitle: Text(instruments.isNotEmpty
              ? instruments.map((i) => i.name).join(', ')
              : 'Select instruments'),
          trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                onInstrumentsChanged([]);
              }),
          onTap: () async {
            final List<Instrument> selection = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InstrumentsSelector(
                    multiple: true,
                    selection: instruments,
                  ),
                  fullscreenDialog: true,
                ));

            if (selection != null) {
              onInstrumentsChanged(selection);
            }
          },
        ),
      ],
    );
  }
}

class PartTile extends StatefulWidget {
  final PartData part;
  final void Function() onMore;
  final void Function() onDelete;

  PartTile({
    Key key,
    @required this.part,
    @required this.onMore,
    @required this.onDelete,
  }) : super(key: key);

  @override
  _PartTileState createState() => _PartTileState();
}

class _PartTileState extends State<PartTile> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 8.0),
          child: Icon(
            Icons.drag_handle,
          ),
        ),
        Expanded(
          child: TextField(
            controller: widget.part.titleController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Part title',
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: widget.onMore,
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: widget.onDelete,
        ),
      ],
    );
  }
}

class WorkEditor extends StatefulWidget {
  final Work work;

  WorkEditor({
    this.work,
  });

  @override
  _WorkEditorState createState() => _WorkEditorState();
}

class _WorkEditorState extends State<WorkEditor> {
  final titleController = TextEditingController();

  BackendState backend;

  String title = '';
  Person composer;
  List<Instrument> instruments = [];
  List<PartData> parts = [];

  @override
  void initState() {
    super.initState();

    if (widget.work != null) {
      titleController.text = widget.work.title;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backend = Backend.of(context);

    if (widget.work != null) {
      if (widget.work.composer != null) {
        () async {
          final person =
              await backend.db.personById(widget.work.composer).getSingle();

          // We don't want to override a newly selected composer.
          if (composer == null) {
            setState(() {
              composer = person;
            });
          }
        }();
      }

      () async {
        final selection =
            await backend.db.instrumentsByWork(widget.work.id).get();

        // We don't want to override already selected instruments.
        if (instruments.isEmpty) {
          setState(() {
            instruments = selection;
          });
        }
      }();

      () async {
        final dbParts = await backend.db.workParts(widget.work.id).get();
        for (final dbPart in dbParts) {
          final partInstruments =
              await backend.db.instrumentsByWork(dbPart.id).get();

          Person partComposer;

          if (dbPart.composer != null) {
            partComposer =
                await backend.db.personById(dbPart.composer).getSingle();
          }

          setState(() {
            parts.add(PartData(
              title: dbPart.title,
              composer: partComposer,
              instruments: partInstruments,
            ));
          });
        }
      }();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> partTiles = [];
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];

      partTiles.add(PartTile(
        key: Key(part.hashCode.toString()),
        part: part,
        onMore: () {
          showDialog(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) => Dialog(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    WorkProperties(
                      titleController: part.titleController,
                      composer: part.composer,
                      instruments: part.instruments,
                      onComposerChanged: (composer) {
                        setState(() {
                          part.composer = composer;
                        });
                      },
                      onInstrumentsChanged: (instruments) {
                        setState(() {
                          part.instruments = instruments;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        onDelete: () {
          setState(() {
            parts.removeAt(i);
          });
        },
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Work'),
        actions: <Widget>[
          FlatButton(
            child: Text('DONE'),
            onPressed: () async {
              final workId = widget.work?.id ?? generateId();

              final model = WorkModel(
                work: Work(
                  id: workId,
                  title: titleController.text,
                  composer: composer?.id,
                ),
                instrumentIds: instruments.map((i) => i.id).toList(),
              );

              final List<WorkModel> partModels = [];
              for (var i = 0; i < parts.length; i++) {
                final part = parts[i];
                partModels.add(WorkModel(
                  work: Work(
                    id: generateId(),
                    title: part.titleController.text,
                    composer: part.composer?.id,
                    partOf: workId,
                    partIndex: i,
                  ),
                  instrumentIds: part.instruments.map((i) => i.id).toList(),
                ));
              }

              await backend.db.updateWork(model, partModels);
              Navigator.pop(context, model.work);
            },
          ),
        ],
      ),
      body: ReorderableListView(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            WorkProperties(
              titleController: titleController,
              composer: composer,
              instruments: instruments,
              onComposerChanged: (newComposer) {
                setState(() {
                  composer = newComposer;
                });
              },
              onInstrumentsChanged: (newInstruments) {
                setState(() {
                  instruments = newInstruments;
                });
              },
            ),
            if (parts.length > 0)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                child: Text(
                  'Parts',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ),
          ],
        ),
        children: partTiles,
        onReorder: (i1, i2) {
          setState(() {
            final part = parts.removeAt(i1);
            final newIndex = i2 > i1 ? i2 - 1 : i2;

            parts.insert(newIndex, part);
          });
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text('Add part'),
        onPressed: () {
          setState(() {
            parts.add(PartData());
          });
        },
      ),
    );
  }
}
