import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/services/crossref_api.dart';
import 'package:wispar/services/abstract_helper.dart';
import 'package:wispar/models/crossref_journals_works_models.dart'
    as journals_works;
import 'package:wispar/widgets/publication_card/publication_card.dart';
import 'package:wispar/screens/publication_card_settings_screen.dart';
import 'package:wispar/widgets/journal_header.dart';
import 'package:wispar/widgets/latest_works_header.dart';
import 'package:wispar/services/database_helper.dart';
import 'package:wispar/services/logs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalDetailsScreen extends StatefulWidget {
  final String title;
  final String publisher;
  final List<String> issn;
  final Function(bool)? onFollowStatusChanged;

  const JournalDetailsScreen({
    super.key,
    required this.title,
    required this.publisher,
    required this.issn,
    this.onFollowStatusChanged,
  });

  @override
  State<JournalDetailsScreen> createState() => _JournalDetailsScreenState();
}

class _JournalDetailsScreenState extends State<JournalDetailsScreen> {
  final logger = LogsService().logger;

  late final PagingController<String?, journals_works.Item> _pagingController;

  String? _latestCursor;

  Map<String, String> abstractCache = {};
  bool _isFollowed = false;

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

    _pagingController = PagingController<String?, journals_works.Item>(
      getNextPageKey: (state) {
        if (state.pages == null || state.pages!.isEmpty) {
          return '*';
        }
        return _latestCursor;
      },
      fetchPage: _fetchPage,
    );

    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCardPreferences();
    await _initFollowStatus();
  }

  Future<List<journals_works.Item>> _fetchPage(String? cursor) async {
    try {
      final response = await CrossRefApi.getJournalWorks(
        issnList: widget.issn,
        cursor: cursor ?? '*',
      );

      _latestCursor = response.nextCursor == null || response.items.isEmpty
          ? null
          : response.nextCursor;

      return response.items;
    } catch (e, stackTrace) {
      logger.severe(
        'Failed to load publications for journal ${widget.issn}.',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _loadCardPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _swipeLeftAction = SwipeAction.values
          .byName(prefs.getString('swipeLeftAction') ?? SwipeAction.hide.name);

      _swipeRightAction = SwipeAction.values.byName(
          prefs.getString('swipeRightAction') ?? SwipeAction.favorite.name);

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

  Future<void> _initFollowStatus() async {
    final dbHelper = DatabaseHelper();
    int? journalId = await dbHelper.getJournalIdByIssns(widget.issn);
    bool isFollowed = false;

    if (journalId != null) {
      isFollowed = await dbHelper.isJournalFollowed(journalId);
    }

    if (!mounted) return;

    setState(() {
      _isFollowed = isFollowed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PagingListener<String?, journals_works.Item>(
        controller: _pagingController,
        builder: (context, state, fetchNextPage) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 250.0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  title: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.fade,
                  ),
                ),
                backgroundColor: Colors.deepPurple,
              ),
              SliverPersistentHeader(
                delegate: JournalInfoHeader(
                  title: widget.title,
                  publisher: widget.publisher,
                  issn: widget.issn.toSet().join(', '),
                  isFollowed: _isFollowed,
                  onFollowStatusChanged: (isFollowed) {
                    setState(() {
                      _isFollowed = isFollowed;
                      widget.onFollowStatusChanged?.call(isFollowed);
                    });
                  },
                ),
              ),
              SliverPersistentHeader(
                delegate: PersistentLatestPublicationsHeader(),
                pinned: true,
              ),
              PagedSliverList<String?, journals_works.Item>(
                state: state,
                fetchNextPage: fetchNextPage,
                builderDelegate: PagedChildBuilderDelegate<journals_works.Item>(
                  itemBuilder: (context, work, index) {
                    final cachedAbstract = abstractCache[work.doi];

                    if (cachedAbstract != null) {
                      return PublicationCard(
                        title: work.title,
                        abstract: cachedAbstract,
                        journalTitle: work.journalTitle,
                        issn: widget.issn,
                        publishedDate: work.publishedDate,
                        doi: work.doi,
                        authors: work.authors,
                        url: work.primaryUrl,
                        license: work.license,
                        licenseName: work.licenseName,
                        publisher: work.publisher,
                        swipeLeftAction: _swipeLeftAction,
                        swipeRightAction: _swipeRightAction,
                        showJournalTitle: _showJournalTitle,
                        showPublicationDate: _showPublicationDate,
                        showAuthorNames: _showAuthorNames,
                        showLicense: _showLicense,
                        showOptionsMenu: _showOptionsMenu,
                        showFavoriteButton: _showFavoriteButton,
                      );
                    }
                    return FutureBuilder<String>(
                      future:
                          AbstractHelper.buildAbstract(context, work.abstract),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final formattedAbstract = snapshot.data ?? '';

                        if (snapshot.hasData) {
                          abstractCache[work.doi] = formattedAbstract;
                        }

                        return PublicationCard(
                          title: work.title,
                          abstract: formattedAbstract,
                          journalTitle: work.journalTitle,
                          issn: widget.issn,
                          publishedDate: work.publishedDate,
                          doi: work.doi,
                          authors: work.authors,
                          url: work.primaryUrl,
                          license: work.license,
                          licenseName: work.licenseName,
                          publisher: work.publisher,
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
                    );
                  },
                  firstPageProgressIndicatorBuilder: (_) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  newPageProgressIndicatorBuilder: (_) => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator())),
                  noItemsFoundIndicatorBuilder: (_) => SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.noPublicationFound,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
