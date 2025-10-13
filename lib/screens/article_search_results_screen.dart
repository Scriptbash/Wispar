import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import '../widgets/publication_card/publication_card.dart';
import '../models/crossref_journals_works_models.dart' as journalsWorks;
import '../services/crossref_api.dart';
import '../services/openAlex_api.dart';
import '../services/logs_helper.dart';

class ArticleSearchResultsScreen extends StatefulWidget {
  final List<journalsWorks.Item> initialSearchResults;
  final bool initialHasMore;
  final Map<String, dynamic> queryParams;
  final String source;

  const ArticleSearchResultsScreen({
    super.key,
    required this.initialSearchResults,
    required this.initialHasMore,
    required this.queryParams,
    required this.source,
  });

  @override
  ArticleSearchResultsScreenState createState() =>
      ArticleSearchResultsScreenState();
}

class ArticleSearchResultsScreenState
    extends State<ArticleSearchResultsScreen> {
  final logger = LogsService().logger;
  late List<journalsWorks.Item> _searchResults;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreResults = true;
  int _currentOpenAlexPage = 1;

  @override
  void initState() {
    super.initState();
    _searchResults = widget.initialSearchResults;
    _hasMoreResults = widget.initialHasMore;

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 70 &&
          !_isLoadingMore &&
          _hasMoreResults) {
        _loadMoreResults();
      }
    });
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || !_hasMoreResults) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      List<journalsWorks.Item> newResults;
      bool hasMore = false;

      if (widget.source == 'Crossref') {
        final ListAndMore<journalsWorks.Item> response =
            await CrossRefApi.getWorksByQuery(widget.queryParams);
        newResults = response.list;
        hasMore =
            response.hasMore && _searchResults.length < response.totalResults;
      } else {
        newResults = await OpenAlexApi.getOpenAlexWorksByQuery(
          widget.queryParams['query'] ?? '',
          widget.queryParams['scope'] ?? 1,
          widget.queryParams['sortField'],
          widget.queryParams['sortOrder'],
          page: _currentOpenAlexPage,
        );

        if (newResults.isNotEmpty) {
          _currentOpenAlexPage++;
        } else {
          hasMore = false;
          _isLoadingMore = false;
        }
      }

      setState(() {
        _searchResults.addAll(newResults);
        _hasMoreResults = hasMore;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.failedLoadMoreResults)),
      );
      logger.severe(
          'Failed to load more article search results.', e, stackTrace);
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
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
        title: Text(AppLocalizations.of(context)!.searchresults),
      ),
      body: _searchResults.isNotEmpty
          ? ListView.builder(
              controller: _scrollController,
              itemCount: _searchResults.length + (_hasMoreResults ? 1 : 0),
              cacheExtent: 1000.0,
              itemBuilder: (context, index) {
                if (index == _searchResults.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final item = _searchResults[index];
                return PublicationCard(
                  title: item.title,
                  abstract: item.abstract,
                  journalTitle: item.journalTitle,
                  issn: item.issn,
                  publishedDate: item.publishedDate,
                  doi: item.doi,
                  authors: item.authors,
                  url: item.url,
                  license: item.license,
                  licenseName: item.licenseName,
                  publisher: item.publisher,
                );
              },
            )
          : Center(
              child: Text(AppLocalizations.of(context)!.noresultsfound),
            ),
    );
  }
}
