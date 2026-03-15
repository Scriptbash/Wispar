import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
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
  final Map<String, dynamic> queryParams;
  final String source;

  const ArticleSearchResultsScreen({
    super.key,
    required this.queryParams,
    required this.source,
  });

  @override
  State<ArticleSearchResultsScreen> createState() =>
      _ArticleSearchResultsScreenState();
}

class _ArticleSearchResultsScreenState
    extends State<ArticleSearchResultsScreen> {
  final logger = LogsService().logger;

  late final PagingController<dynamic, journals_works.Item> _pagingController;

  String? _latestCrossrefCursor;
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

    _pagingController = PagingController<dynamic, journals_works.Item>(
      getNextPageKey: (state) {
        if (widget.source == 'Crossref') {
          if (state.pages == null || state.pages!.isEmpty) {
            return '*';
          }
          return _latestCrossrefCursor;
        } else {
          if (state.pages == null || state.pages!.isEmpty) {
            return 1;
          }
          return _currentOpenAlexPage;
        }
      },
      fetchPage: _fetchPage,
    );

    _loadCardPreferences();
  }

  Future<List<journals_works.Item>> _fetchPage(dynamic pageKey) async {
    try {
      if (widget.source == 'Crossref') {
        final response = await CrossRefApi.getWorksByQuery(
          queryParams: widget.queryParams,
          cursor: pageKey ?? '*',
        );

        _latestCrossrefCursor =
            response.nextCursor == null || response.items.isEmpty
                ? null
                : response.nextCursor;

        return response.items;
      } else {
        final newItems = await OpenAlexApi.getOpenAlexWorksByQuery(
          widget.queryParams['query'] ?? '',
          widget.queryParams['scope'] ?? 1,
          widget.queryParams['sortField'],
          widget.queryParams['sortOrder'],
          widget.queryParams['dateFilter'],
          widget.queryParams['issnFilter'],
          widget.queryParams['isOpenAccess'] ?? false,
          page: pageKey,
        );

        if (newItems.isNotEmpty) {
          _currentOpenAlexPage = pageKey + 1;
        }

        return newItems;
      }
    } catch (e, stackTrace) {
      logger.severe(
        'Failed to fetch article search results.',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _loadCardPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final leftActionName =
        prefs.getString('swipeLeftAction') ?? SwipeAction.hide.name;
    final rightActionName =
        prefs.getString('swipeRightAction') ?? SwipeAction.favorite.name;

    if (!mounted) return;

    setState(() {
      _swipeLeftAction = SwipeAction.values.byName(leftActionName);
      _swipeRightAction = SwipeAction.values.byName(rightActionName);

      _showJournalTitle =
          prefs.getBool(PublicationCardSettingsScreen.showJournalTitleKey) ??
              true;
      _showPublicationDate =
          prefs.getBool(PublicationCardSettingsScreen.showPublicationDateKey) ??
              true;
      _showAuthorNames =
          prefs.getBool(PublicationCardSettingsScreen.showAuthorNamesKey) ??
              true;
      _showLicense =
          prefs.getBool(PublicationCardSettingsScreen.showLicenseKey) ?? true;
      _showOptionsMenu =
          prefs.getBool(PublicationCardSettingsScreen.showOptionsMenuKey) ??
              true;
      _showFavoriteButton =
          prefs.getBool(PublicationCardSettingsScreen.showFavoriteButtonKey) ??
              true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.searchresults),
      ),
      body: PagingListener<dynamic, journals_works.Item>(
        controller: _pagingController,
        builder: (context, state, fetchNextPage) {
          return PagedListView<dynamic, journals_works.Item>(
            state: state,
            fetchNextPage: fetchNextPage,
            builderDelegate: PagedChildBuilderDelegate<journals_works.Item>(
              itemBuilder: (context, item, index) {
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
              firstPageProgressIndicatorBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
              newPageProgressIndicatorBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
              noItemsFoundIndicatorBuilder: (_) => Center(
                child: Text(
                  AppLocalizations.of(context)!.noresultsfound,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
