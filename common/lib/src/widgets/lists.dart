import 'dart:async';

import 'package:flutter/material.dart';

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
