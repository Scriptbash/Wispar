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
  int cursor = 0;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late DatabaseHelper dbHelper;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    _scrollController.addListener(_onScroll);
    loadMoreItems(widget.searchQuery);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
      ),
      body: ListView.builder(
        itemCount: items.length + 1, // +1 for the loading indicator
        itemBuilder: (context, index) {
          if (index == items.length) {
            // Display loading indicator at the end of the list
            return isLoading ? CircularProgressIndicator() : Container();
          } else {
            // Check if issn is not empty
            if (items[index].issn.isNotEmpty) {
              return FutureBuilder<bool>(
                future: dbHelper.isJournalFollowed(items[index].issn.first),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    bool isFollowed = snapshot.data ?? false;
                    return JournalsSearchResultCard(
                      key: UniqueKey(), // Ensure each card has a unique key
                      item: items[index],
                      isFollowed: isFollowed,
                    );
                  }
                },
              );
            } else {
              // Skip creating a card if issn is missing
              return Container();
            }
          }
        },
        controller: _scrollController,
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // User reached the end of the list
      if (!isLoading) {
        loadMoreItems(widget.searchQuery); // Pass the search query
      }
    }
  }

  Future<void> loadMoreItems(String query) async {
    try {
      setState(() {
        isLoading = true;
      });

      // Use the provided query
      List<Journals.Item> newItems = await CrossRefApi.queryJournals(query);

      // Add new items to the beginning of the list
      setState(() {
        items.insertAll(0, newItems);
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
