import 'package:flutter/material.dart';
import '../services/crossref_api.dart';
import '../services/database_helper.dart';
import '../models/crossref_journals_models.dart' as Journals;

class SearchResultsScreen extends StatefulWidget {
  final List<Journals.Item> searchResults;
  final String searchQuery;

  const SearchResultsScreen({
    Key? key,
    required this.searchResults,
    required this.searchQuery,
  }) : super(key: key);

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Journals.Item> items = [];
  bool isLoading = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    items = widget.searchResults;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
      ),
      body: ListView.builder(
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == items.length) {
            // Display loading indicator at the end of the list
            return isLoading ? CircularProgressIndicator() : Container();
          } else {
            return JournalsSearchResultCard(
              key: UniqueKey(),
              item: items[index],
              isFollowed: false, // Update this as needed
            );
          }
        },
        controller: _scrollController,
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!isLoading) {
        // Check if there are more items to load
        int totalResults = widget.searchResults.length;
        if (items.length >= totalResults) {
          // End of the result set, do not load more items
          return;
        }

        // Load more items
        loadMoreItems(widget.searchQuery);
      }
    }
  }

  Future<void> loadMoreItems(String query) async {
    try {
      setState(() {
        isLoading = true;
      });

      // Use the current cursor for lazy loading
      List<Journals.Item> newItems = await CrossRefApi.queryJournals(query);

      setState(() {
        items.addAll(newItems);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading more items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
}

class JournalsSearchResultCard extends StatefulWidget {
  final Journals.Item item;
  final bool isFollowed;

  const JournalsSearchResultCard(
      {Key? key, required this.item, required this.isFollowed})
      : super(key: key);

  @override
  _JournalsSearchResultCardState createState() =>
      _JournalsSearchResultCardState();
}

class _JournalsSearchResultCardState extends State<JournalsSearchResultCard> {
  late bool _isFollowed;

  @override
  void initState() {
    super.initState();
    _isFollowed = widget.isFollowed;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(widget.item.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Publisher: ${widget.item.publisher}'),
            if (widget.item.issn.isNotEmpty)
              Text('ISSN: ${widget.item.issn.first}'),
          ],
        ),
        trailing: FollowButton(
          item: widget.item,
          isFollowed: _isFollowed,
          onFollowStatusChanged: (isFollowed) {
            // Handle follow status changes
            setState(() {
              _isFollowed = isFollowed;
            });
          },
        ),
      ),
    );
  }
}

class FollowButton extends StatelessWidget {
  final Journals.Item item;
  final bool isFollowed;
  final Function(bool) onFollowStatusChanged;

  const FollowButton({
    Key? key,
    required this.item,
    required this.isFollowed,
    required this.onFollowStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        toggleFollowStatus(context);
      },
      child: Text(isFollowed ? 'Unfollow' : 'Follow'),
    );
  }

  void toggleFollowStatus(BuildContext context) async {
    final dbHelper = DatabaseHelper();

    if (isFollowed) {
      // Unfollow
      await dbHelper.removeJournal(item.issn.first);
    } else {
      // Follow
      await dbHelper.insertJournal(
        Journal(
          issn: item.issn.first,
          title: item.title,
          publisher: item.publisher,
          subjects: item.subjects.join(', '),
        ),
      );
    }

    onFollowStatusChanged(!isFollowed);
  }
}
