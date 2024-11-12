import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/crossref_api.dart';
import '../services/database_helper.dart';
import '../models/crossref_journals_models.dart' as Journals;
import './journals_details_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final ListAndMore<Journals.Item> searchResults;
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
  bool hasMoreResults = true;
  bool reachedEnd = false;
  bool waitingForMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    if (widget.searchResults.list.isNotEmpty) {
      items = widget.searchResults.list;
      hasMoreResults = widget.searchResults.hasMore;
    } else {
      // Handle empty searchResults
      hasMoreResults = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.searchresults),
      ),
      body: ListView.builder(
        itemCount: items.length + (hasMoreResults ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            // Display loading indicator at the end of the list
            return isLoading ? CircularProgressIndicator() : Container();
          } else {
            Journals.Item currentItem = items[index];

            // Check if the current item has non-empty ISSN
            if (currentItem.issn.isNotEmpty) {
              return JournalsSearchResultCard(
                key: UniqueKey(),
                item: currentItem,
                isFollowed: false,
              );
            } else {
              // Skip creating a card for items with empty ISSN
              return Container();
            }
          }
        },
        controller: _scrollController,
      ),
    );
  }

  void _onScroll() {
    if (hasMoreResults &&
        _scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
      if (!isLoading && !waitingForMore) {
        loadMoreItems(widget.searchQuery);
      }
    }
  }

  Future<void> loadMoreItems(String query) async {
    try {
      setState(() {
        isLoading = true;
        waitingForMore = true;
      });

      if (reachedEnd) {
        // Clear the flag if we are making a new API call
        reachedEnd = false;
      }

      ListAndMore<Journals.Item> newItems =
          await CrossRefApi.queryJournals(query);

      setState(() {
        items.addAll(newItems.list);
        hasMoreResults = newItems.hasMore &&
            newItems.list.length >= 50; // Adjust the condition
        isLoading = false;
      });
    } catch (e) {
      print('Error loading more items: $e');
      setState(() {
        isLoading = false;
      });
    } finally {
      // Reset the waitingForMore flag regardless of success or failure
      waitingForMore = false;
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
  late bool _isFollowed = false; // Initialize with false by default

  @override
  void initState() {
    super.initState();
    _initFollowStatus();
  }

  Future<void> _initFollowStatus() async {
    final dbHelper = DatabaseHelper();
    bool isFollowed = await dbHelper.isJournalFollowed(widget.item.issn.first);
    setState(() {
      _isFollowed = isFollowed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(
          widget.item.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${AppLocalizations.of(context)!.publisher}: ${widget.item.publisher}'),
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
        onTap: () {
          List<String> subjectNames =
              widget.item.subjects.map((subject) => subject.name).toList();
          // Navigate to the detailed screen when the card is tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JournalDetailsScreen(
                title: widget.item.title,
                publisher: widget.item.publisher,
                issn: widget.item.issn.first,
                subjects: subjectNames,
              ),
            ),
          );
        },
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
      child: Text(isFollowed
          ? AppLocalizations.of(context)!.unfollow
          : AppLocalizations.of(context)!.follow),
    );
  }

  void toggleFollowStatus(BuildContext context) async {
    final dbHelper = DatabaseHelper();

    // Check if the journal is currently followed
    bool currentlyFollowed = await dbHelper.isJournalFollowed(item.issn.first);

    if (currentlyFollowed) {
      // Unfollow
      await dbHelper.removeJournal(item.issn.first);
    } else {
      // Follow
      List<String> subjectNames =
          item.subjects.map((subject) => subject.name).toList();
      await dbHelper.insertJournal(
        Journal(
          issn: item.issn.first,
          title: item.title,
          publisher: item.publisher,
          subjects: subjectNames.join(', '),
        ),
      );
    }

    //await dbHelper.clearCachedPublications();
    onFollowStatusChanged(!currentlyFollowed);
  }
}
