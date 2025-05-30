import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import '../services/crossref_api.dart';
import '../models/crossref_journals_models.dart' as Journals;
import '../widgets/journal_search_results_card.dart';
import '../services/logs_helper.dart';

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
  final logger = LogsService().logger;
  List<Journals.Item> items = [];
  bool isLoading = false;
  late ScrollController _scrollController;
  bool hasMoreResults = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    if (widget.searchResults.list.isNotEmpty) {
      items = widget.searchResults.list;
      hasMoreResults = widget.searchResults.hasMore;
    } else {
      hasMoreResults = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.searchresults),
      ),
      body: items.isEmpty
          ? Center(
              child: Text(AppLocalizations.of(context)!.noPublicationFound),
            )
          : ListView.builder(
              itemCount: items.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == items.length && isLoading) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  Journals.Item currentItem = items[index];

                  // Skip invalid items
                  if (currentItem.issn.isEmpty) return SizedBox.shrink();

                  return JournalsSearchResultCard(
                    key: UniqueKey(),
                    item: currentItem,
                    isFollowed: false,
                  );
                }
              },
              controller: _scrollController,
            ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !isLoading &&
        hasMoreResults) {
      loadMoreItems(widget.searchQuery);
    }
  }

  Future<void> loadMoreItems(String query) async {
    setState(() => isLoading = true);

    try {
      ListAndMore<Journals.Item> newResults =
          await CrossRefApi.queryJournalsByName(query);

      setState(() {
        if (newResults.list.isNotEmpty) {
          items.addAll(newResults.list);
          hasMoreResults = newResults.hasMore;
        } else {
          hasMoreResults = false;
        }
      });
    } catch (e, stackTrace) {
      logger.severe('Failed to load more journals.', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context)!.failLoadMorePublication)));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
