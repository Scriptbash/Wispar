import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/widgets/publication_card/publication_card.dart';
import 'package:wispar/screens/publication_card_settings_screen.dart';
import 'package:wispar/models/crossref_journals_works_models.dart'
    as journals_works;
import 'package:wispar/services/crossref_api.dart';
import 'package:wispar/services/openAlex_api.dart';
import 'package:wispar/services/logs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticleSearchResultsScreen extends StatefulWidget {
  final List<journals_works.Item> initialSearchResults;
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
  late List<journals_works.Item> _searchResults;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreResults = true;
  int _currentOpenAlexPage = 1;

  SwipeAction _swipeLeftAction = SwipeAction.hide;
  SwipeAction _swipeRightAction = SwipeAction.favorite;

  bool _showJournalTitle = true;
  bool _showPublicationDate = true;
  bool _showAuthorNames = true;
  bool _showLicense = true;
  bool _showOptionsMenu = true;
  bool _showFavoriteButton = true;

  @override
  void initState() {
    super.initState();
    _searchResults = widget.initialSearchResults;
    _hasMoreResults = widget.initialHasMore;

    _loadCardPreferences();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 70 &&
          !_isLoadingMore &&
          _hasMoreResults) {
        _loadMoreResults();
      }
    });
  }

  Future<void> _loadCardPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final leftActionName =
        prefs.getString('swipeLeftAction') ?? SwipeAction.hide.name;
    final rightActionName =
        prefs.getString('swipeRightAction') ?? SwipeAction.favorite.name;

    SwipeAction newLeftAction = SwipeAction.hide;
    SwipeAction newRightAction = SwipeAction.favorite;

    try {
      newLeftAction = SwipeAction.values.byName(leftActionName);
    } catch (_) {
      newLeftAction = SwipeAction.hide;
    }
    try {
      newRightAction = SwipeAction.values.byName(rightActionName);
    } catch (_) {
      newRightAction = SwipeAction.favorite;
    }

    if (mounted) {
      setState(() {
        _swipeLeftAction = newLeftAction;
        _swipeRightAction = newRightAction;
        _showJournalTitle =
            prefs.getBool(PublicationCardSettingsScreen.showJournalTitleKey) ??
                true;
        _showPublicationDate = prefs.getBool(
                PublicationCardSettingsScreen.showPublicationDateKey) ??
            true;
        _showAuthorNames =
            prefs.getBool(PublicationCardSettingsScreen.showAuthorNamesKey) ??
                true;
        _showLicense =
            prefs.getBool(PublicationCardSettingsScreen.showLicenseKey) ?? true;
        _showOptionsMenu =
            prefs.getBool(PublicationCardSettingsScreen.showOptionsMenuKey) ??
                true;
        _showFavoriteButton = prefs
                .getBool(PublicationCardSettingsScreen.showFavoriteButtonKey) ??
            true;
      });
    }
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || !_hasMoreResults) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      List<journals_works.Item> newResults;
      bool hasMore = false;

      if (widget.source == 'Crossref') {
        final ListAndMore<journals_works.Item> response =
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
                  swipeLeftAction: _swipeLeftAction,
                  swipeRightAction: _swipeRightAction,
                  showJournalTitle: _showJournalTitle,
                  showPublicationDate: _showPublicationDate,
                  showAuthorNames: _showAuthorNames,
                  showLicense: _showLicense,
                  showOptionsMenu: _showOptionsMenu,
                  showFavoriteButton: _showFavoriteButton,
                );
              },
            )
          : Center(
              child: Text(AppLocalizations.of(context)!.noresultsfound),
            ),
    );
  }
}
