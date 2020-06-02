import 'dart:async';

import 'package:flutter/material.dart';
import 'package:musicus_client/musicus_client.dart';

import '../backend.dart';
import '../widgets/texts.dart';

/// A list view supporting pagination and searching.
///
/// The [fetch] function will be called, when the user has scrolled to the end
/// of the list. If you recreate this widget with a new [search] parameter, it
/// will update, but it will NOT correctly react to a changed [fetch] method.
/// You can call update() on the corresponding state object to manually refresh
/// the contents.
class PagedListView<T> extends StatefulWidget {
  /// A search string.
  ///
  /// This will be provided when calling [fetch].
  final String search;

  /// Callback for fetching a page of entities.
  ///
  /// This has to tolerate abitrary high page numbers.
  final Future<List<T>> Function(int page, String search) fetch;

  /// Build function to be called for each entity.
  final Widget Function(BuildContext context, T entity) builder;

  PagedListView({
    Key key,
    this.search,
    @required this.fetch,
    @required this.builder,
  }) : super(key: key);

  @override
  PagedListViewState<T> createState() => PagedListViewState<T>();
}

class PagedListViewState<T> extends State<PagedListView<T>> {
  final _scrollController = ScrollController();
  final _entities = <T>[];

  bool loading = true;

  /// The last parameters of _fetch().
  int _page;
  String _search;

  /// Whether the last fetch() call returned no results.
  bool _end = false;

  /// Fetch new entities.
  ///
  /// If the function was called again with other parameters, while it was
  /// running, it will discard the result.
  Future<void> _fetch(int page, String search) async {
    if (page != _page || search != _search) {
      _page = page;
      _search = search;

      setState(() {
        loading = true;
      });

      final newEntities = await widget.fetch(page, search);

      if (mounted && search == _search) {
        setState(() {
          if (newEntities.isNotEmpty) {
            _entities.addAll(newEntities);
          } else {
            _end = true;
          }

          loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - 64.0 &&
          !loading &&
          !_end) {
        _fetch(_page + 1, widget.search);
      }
    });

    _fetch(0, widget.search);
  }

  /// Update the content manually.
  /// 
  /// This will reset the current page to zero and call the provided fetch()
  /// method.
  void update() {
    setState(() {
      _entities.clear();
    });

    _page = null;
    _fetch(0, widget.search);
  }

  @override
  void didUpdateWidget(PagedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.search != widget.search) {
      // We don't nedd to call setState() because the framework will always call
      // build() after this.
      _entities.clear();
      _page = null;
      _fetch(0, widget.search);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _entities.length + 1,
      itemBuilder: (context, index) {
        if (index < _entities.length) {
          return widget.builder(context, _entities[index]);
        } else {
          return SizedBox(
            height: 64.0,
            child: Center(
              child: loading ? CircularProgressIndicator() : Container(),
            ),
          );
        }
      },
    );
  }
}

/// A list of persons.
class PersonsList extends StatefulWidget {
  /// Called, when the user has selected a person.
  final void Function(Person person) onSelected;

  PersonsList({
    @required this.onSelected,
  });

  @override
  _PersonsListState createState() => _PersonsListState();
}

class _PersonsListState extends State<PersonsList> {
  String _search;

  @override
  Widget build(BuildContext context) {
    final backend = MusicusBackend.of(context);

    return Column(
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
                hintText: 'Search by last name...',
              ),
            ),
          ),
        ),
        Expanded(
          child: PagedListView<Person>(
            search: _search,
            fetch: (page, search) async {
              return await backend.client.getPersons(page, search);
            },
            builder: (context, person) => ListTile(
              title: Text('${person.lastName}, ${person.firstName}'),
              onTap: () {
                widget.onSelected(person);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A list of ensembles.
class EnsemblesList extends StatefulWidget {
  /// Called, when the user has selected an ensemble.
  final void Function(Ensemble ensemble) onSelected;

  EnsemblesList({
    @required this.onSelected,
  });

  @override
  _EnsemblesListState createState() => _EnsemblesListState();
}

class _EnsemblesListState extends State<EnsemblesList> {
  String _search;

  @override
  Widget build(BuildContext context) {
    final backend = MusicusBackend.of(context);

    return Column(
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
          child: PagedListView<Ensemble>(
            search: _search,
            fetch: (page, search) async {
              return await backend.client.getEnsembles(page, search);
            },
            builder: (context, ensemble) => ListTile(
              title: Text(ensemble.name),
              onTap: () {
                widget.onSelected(ensemble);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A list of works by one composer.
class WorksList extends StatefulWidget {
  /// The ID of the composer.
  final int personId;

  /// Called, when the user has selected a work.
  final void Function(WorkInfo workInfo) onSelected;

  WorksList({
    this.personId,
    this.onSelected,
  });

  @override
  _WorksListState createState() => _WorksListState();
}

class _WorksListState extends State<WorksList> {
  String _search;

  @override
  Widget build(BuildContext context) {
    final backend = MusicusBackend.of(context);

    return Column(
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
                hintText: 'Search by title...',
              ),
            ),
          ),
        ),
        Expanded(
          child: PagedListView<WorkInfo>(
            search: _search,
            fetch: (page, search) async {
              return await backend.client
                  .getWorks(widget.personId, page, search);
            },
            builder: (context, workInfo) => ListTile(
              title: Text(workInfo.work.title),
              onTap: () {
                widget.onSelected(workInfo);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A list of recordings of a work.
class RecordingsList extends StatelessWidget {
  /// The ID of the work.
  final int workId;

  /// Called, when the user has selected a recording.
  final void Function(RecordingInfo recordingInfo) onSelected;

  RecordingsList({
    this.workId,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final backend = MusicusBackend.of(context);

    return PagedListView<RecordingInfo>(
      fetch: (page, _) async {
        return await backend.client.getRecordings(workId, page);
      },
      builder: (context, recordingInfo) => ListTile(
        title: PerformancesText(
          performanceInfos: recordingInfo.performances,
        ),
        onTap: () {
          if (onSelected != null) {
            onSelected(recordingInfo);
          }
        },
      ),
    );
  }
}
