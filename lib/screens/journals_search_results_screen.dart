import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/crossref_api.dart';
import '../models/crossref_journals_models.dart' as Journals;
import '../widgets/journal_search_results_card.dart';

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
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
        hasMoreResults = newItems.hasMore && newItems.list.length >= 30;
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
