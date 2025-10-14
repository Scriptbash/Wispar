import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/services/crossref_api.dart';
import 'package:wispar/services/abstract_helper.dart';
import 'package:wispar/models/crossref_journals_works_models.dart'
    as journals_works;
import 'package:wispar/widgets/publication_card/publication_card.dart';
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
  JournalDetailsScreenState createState() => JournalDetailsScreenState();
}

class JournalDetailsScreenState extends State<JournalDetailsScreen> {
  final logger = LogsService().logger;
  late List<journals_works.Item> allWorks;
  bool isLoading = false;
  late ScrollController _scrollController;
  bool hasMoreResults = true;
  Map<String, String> abstractCache = {};
  late bool _isFollowed = false;

  SwipeAction _swipeLeftAction = SwipeAction.hide;
  SwipeAction _swipeRightAction = SwipeAction.favorite;

  @override
  void initState() {
    super.initState();
    allWorks = [];
    CrossRefApi.resetJournalWorksCursor();
    _loadAllData();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _loadMoreWorks();
  }

  Future<void> _loadAllData() async {
    await _loadSwipePreferences();
    await _initFollowStatus();
    await _loadMoreWorks();
  }

  Future<void> _loadSwipePreferences() async {
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
      });
    }
  }

  Future<void> _initFollowStatus() async {
    final dbHelper = DatabaseHelper();
    int? journalId = await dbHelper.getJournalIdByIssns(widget.issn);
    bool isFollowed = false;
    if (journalId != null) {
      isFollowed = await dbHelper.isJournalFollowed(journalId);
    }

    if (mounted) {
      setState(() {
        _isFollowed = isFollowed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 50,
                vertical: 8.0,
              ),
              centerTitle: true,
              title: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
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
            pinned: false,
          ),
          SliverPersistentHeader(
            delegate: PersistentLatestPublicationsHeader(),
            pinned: true,
          ),
          allWorks.isEmpty && !isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noPublicationFound,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < allWorks.length) {
                        final work = allWorks[index];
                        String? cachedAbstract = abstractCache[work.doi];
                        if (cachedAbstract == null) {
                          return FutureBuilder<String>(
                            future: AbstractHelper.buildAbstract(
                                context, work.abstract),
                            builder: (context, abstractSnapshot) {
                              if (abstractSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              } else if (abstractSnapshot.hasError) {
                                return Center(
                                    child: Text(
                                        'Error: ${abstractSnapshot.error}'));
                              } else if (!abstractSnapshot.hasData) {
                                return const Center(
                                    child: Text('No abstract available'));
                              } else {
                                String formattedAbstract =
                                    abstractSnapshot.data!;
                                // Cache the abstract
                                abstractCache[work.doi] = formattedAbstract;

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
                                );
                              }
                            },
                          );
                        } else {
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
                          );
                        }
                      } else if (hasMoreResults) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                    childCount: allWorks.length + (hasMoreResults ? 1 : 0),
                  ),
                ),
        ],
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !isLoading &&
        hasMoreResults) {
      _loadMoreWorks();
    }
  }

  Future<void> _loadMoreWorks() async {
    setState(() => isLoading = true);

    try {
      ListAndMore<journals_works.Item> newWorks =
          await CrossRefApi.getJournalWorks(widget.issn);

      setState(() {
        allWorks.addAll(newWorks.list);
        hasMoreResults = newWorks.hasMore && newWorks.list.isNotEmpty;
      });
    } catch (e, stackTrace) {
      logger.severe(
          'Failed to load more publications for journal ${widget.issn}.',
          e,
          stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.failLoadMorePublication),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
