import 'package:flutter/material.dart';
import 'package:musicus_database/musicus_database.dart';

import '../backend.dart';
import '../selectors/instruments.dart';
import '../selectors/person.dart';

class PartData {
  final bool isSection;
  final titleController = TextEditingController();

  Person composer;
  List<Instrument> instruments;

  PartData({
    this.isSection = false,
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
    this.onMore,
    @required this.onDelete,
  }) : super(key: key);

  @override
  _PartTileState createState() => _PartTileState();
}

class _PartTileState extends State<PartTile> {
  @override
  Widget build(BuildContext context) {
    final isSection = widget.part.isSection;

    return Row(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: isSection ? 8.0 : 24.0, right: 8.0),
          child: Icon(
            Icons.drag_handle,
          ),
        ),
        Expanded(
          child: TextField(
            controller: widget.part.titleController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: isSection ? 'Section title' : 'Part title',
            ),
          ),
        ),
        if (!isSection)
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

/// Screen for editing a work.
///
/// If the user is finished editing, the result will be returned as a [WorkInfo]
/// object.
class WorkEditor extends StatefulWidget {
  /// The work to edit.
  ///
  /// If this is null, a new work will be created.
  final WorkInfo workInfo;

  WorkEditor({
    this.workInfo,
  });

  @override
  _WorkEditorState createState() => _WorkEditorState();
}

class _WorkEditorState extends State<WorkEditor> {
  final titleController = TextEditingController();

  bool uploading = false;
  Person composer;
  List<Instrument> instruments = [];
  List<PartData> parts = [];

  @override
  void initState() {
    super.initState();

    if (widget.workInfo != null) {
      titleController.text = widget.workInfo.work.title;
      // TODO: Theoretically this includes the composers of all parts.
      composer = widget.workInfo.composers.first;
      instruments = List.from(widget.workInfo.instruments);

      for (final partInfo in widget.workInfo.parts) {
        parts.add(PartData(
          title: partInfo.part.title,
          composer: partInfo.composer,
          instruments: List.from(partInfo.instruments),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = MusicusBackend.of(context);

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
          uploading
              ? Padding(
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
                )
              : FlatButton(
                  child: Text('DONE'),
                  onPressed: () async {
                    setState(() {
                      uploading = true;
                    });

                    final workId = widget?.workInfo?.work?.id ?? generateId();

                    List<PartInfo> partInfos = [];
                    List<WorkSection> sections = [];
                    int sectionCount = 0;
                    for (var i = 0; i < parts.length; i++) {
                      final part = parts[i];
                      if (part.isSection) {
                        sections.add(WorkSection(
                          id: generateId(),
                          work: workId,
                          title: part.titleController.text,
                          beforePartIndex: i - sectionCount,
                        ));
                        sectionCount++;
                      } else {
                        partInfos.add(PartInfo(
                          part: WorkPart(
                            id: generateId(),
                            title: part.titleController.text,
                            composer: part.composer?.id,
                            partOf: workId,
                            partIndex: i - sectionCount,
                          ),
                          instruments: part.instruments,
                          composer: part.composer,
                        ));
                      }
                    }

                    final workInfo = WorkInfo(
                      work: Work(
                        id: workId,
                        title: titleController.text,
                        composer: composer?.id,
                      ),
                      instruments: instruments,
                      // TODO: Theoretically, this should include all composers
                      // from the parts.
                      composers: [composer],
                      parts: partInfos,
                      sections: sections,
                    );

                    final success = await backend.client.putWork(workInfo);

                    setState(() {
                      uploading = false;
                    });

                    if (success) {
                      Navigator.pop(context, workInfo);
                    } else {
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text('Failed to upload'),
                      ));
                    }
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
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Parts',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  FlatButton(
                    child: Text('ADD SECTION'),
                    onPressed: () {
                      setState(() {
                        parts.add(PartData(
                          isSection: true,
                        ));
                      });
                    },
                  ),
                  FlatButton(
                    child: Text('ADD PART'),
                    onPressed: () {
                      setState(() {
                        parts.add(PartData());
                      });
                    },
                  ),
                ],
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
    );
  }
}
