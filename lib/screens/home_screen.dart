import 'package:flutter/material.dart';
import 'dart:async';
import '../generated_l10n/app_localizations.dart';
import 'settings_screen.dart';
import '../services/database_helper.dart';
import '../services/feed_service.dart';
import '../services/abstract_helper.dart';
import '../models/feed_filter_entity.dart';
import '../widgets/publication_card.dart';
import '../widgets/sort_dialog.dart';
import '../widgets/custom_feed_bottom_sheet.dart';
import './hidden_articles_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/logs_helper.dart';
import '../widgets/appbar_dropdown_menu.dart';
import 'dart:io' show Platform;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final logger = LogsService().logger;
  final DatabaseHelper dbHelper = DatabaseHelper();
  final StreamController<List<PublicationCard>> _feedStreamController =
      StreamController<List<PublicationCard>>();

  String _currentFeedName = 'Home'; // Default feed (no filter)
  int sortBy = 0; // Set the default sort by to published date
  int sortOrder = 1; // Set the default sort order to descending
  int fetchIntervalInHours = 6; // Default to 6 hours for API fetch
  int _concurrentFetches = 3; // Default to 3 concurrent requests
  List<String> _currentJournalNames = [];

  // Variables related to the search bar in the appbar
  bool _isSearching = false;
  final TextEditingController _filterController = TextEditingController();
  List<PublicationCard> _allFeed = [];
  List<PublicationCard> _filteredFeed = [];
  List<PublicationCard> _activeFeed = [];

  final FeedService _feedService = FeedService();

  List<Map<String, dynamic>> savedQueries = [];
  bool _feedLoaded = false; // Needed to avoid conflicts wih onAbstractChanged
  bool _useAndFilter = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _buildAndStreamFeed();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Platform.isAndroid || Platform.isIOS) {
        await checkAndSetNotificationPermissions();
        if (_feedLoaded) {
          _onAbstractChanged();
        }
      }
    });

    _filterController.addListener(() {
      _filterFeed(_filterController.text);
    });
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fetchIntervalInHours = prefs.getInt('fetchInterval') ?? 6;
      _concurrentFetches = prefs.getInt('concurrentFetches') ?? 3;
    });

    final lastFeedName = prefs.getString('lastSelectedFeed');
    if (lastFeedName != null && lastFeedName != 'Home') {
      final filters = await dbHelper.getParsedFeedFilters();
      final match = filters.firstWhere(
        (f) => f.name == lastFeedName,
        orElse: () => FeedFilter(
          id: 0,
          name: 'Home',
          include: '',
          exclude: '',
          journals: <String>{},
          dateCreated: '',
        ),
      );

      if (match.name != 'Home') {
        setState(() {
          _currentFeedName = match.name;
        });
        _applyAdvancedFilters(
            match.name, match.journals, match.include, match.exclude);
      }
    } else {
      setState(() {
        _currentFeedName = 'Home';
        _activeFeed = List.from(_allFeed);
        _filteredFeed = List.from(_allFeed);
      });
    }
  }

  Future<void> checkAndSetNotificationPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final bool deniedBefore = prefs.getBool('notification_perms') ?? false;

    if (deniedBefore) return; // Don't ask if user denied before

    final permissionGranted = await _requestNotificationPermission();

    if (!permissionGranted) {
      await prefs.setBool('notification_perms', true);
    } else {
      await prefs.setBool('notification_perms', false);
    }
  }

  Future<bool> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isDenied || status.isLimited) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return false;
  }

  Future<void> _buildAndStreamFeed() async {
    try {
      final followedJournals = await dbHelper.getFollowedJournals();
      List<Map<String, dynamic>> savedQueries =
          await dbHelper.getSavedQueriesToUpdate();
      if (mounted && followedJournals.isNotEmpty) {
        await _feedService.updateFeed(
          followedJournals,
          (List<String> journalNames) {
            if (mounted) {
              setState(() {
                _currentJournalNames = journalNames;
              });
            }
          },
          fetchIntervalInHours,
          _concurrentFetches,
        );
      }

      if (mounted && savedQueries.isNotEmpty) {
        await _feedService.updateSavedQueryFeed(savedQueries,
            (List<String> queryNames) {
          if (mounted) {
            setState(() {
              _currentJournalNames = queryNames;
            });
          }
        }, fetchIntervalInHours, _concurrentFetches);
      }

      if (mounted) {
        final List<PublicationCard> cachedFeed =
            await _getCachedFeed(context, _onAbstractChanged);

        setState(() {
          _allFeed = List.from(cachedFeed);
          _filteredFeed = List.from(_allFeed);
          if (_currentFeedName != 'Home') {
            _applyStoredFilter();
          } else {
            setState(() {
              _activeFeed = List.from(_allFeed);
              _filteredFeed = List.from(_allFeed);
            });
          }

          _sortFeed();
          _feedLoaded = true;
        });

        _feedStreamController.add(_filteredFeed);
      }
    } catch (e, stackTrace) {
      logger.severe("Unable to build the feed.", e, stackTrace);
      if (mounted) {
        _feedStreamController.addError(e);
      }
    }
  }

  void _sortFeed() {
    setState(() {
      _filteredFeed.sort((a, b) {
        switch (sortBy) {
          case 0: // Sort by published date
            return a.publishedDate!.compareTo(b.publishedDate!);

          case 1: // Sort by title
            if (a.title.isEmpty && b.title.isEmpty) return 0;
            if (a.title.isEmpty) return 1;
            if (b.title.isEmpty) return -1;
            return a.title.compareTo(b.title);

          case 2: // Sort by journal title
            if (a.journalTitle.isEmpty && b.journalTitle.isEmpty) return 0;
            if (a.journalTitle.isEmpty) return 1;
            if (b.journalTitle.isEmpty) return -1;
            return a.journalTitle.compareTo(b.journalTitle);

          case 3: // Sort by first author's family name
            String aFamily = (a.authors.isNotEmpty ? a.authors[0].family : '');
            String bFamily = (b.authors.isNotEmpty ? b.authors[0].family : '');
            if (aFamily.isEmpty && bFamily.isEmpty) return 0;
            if (aFamily.isEmpty) return 1;
            if (bFamily.isEmpty) return -1;
            return aFamily.compareTo(bFamily);

          default:
            return 0;
        }
      });

      if (sortOrder == 1) {
        _filteredFeed = _filteredFeed.reversed.toList();
      }

      _feedStreamController.add(_filteredFeed);
    });
  }

  // Filters the feed using the filter bar
  void _filterFeed(String query) {
    final sourceFeed = _activeFeed.isNotEmpty ? _activeFeed : _allFeed;

    setState(() {
      if (query.isEmpty) {
        _filteredFeed = List.from(sourceFeed);
      } else {
        List<String> keywords = query.toLowerCase().split(' ');

        _filteredFeed = sourceFeed.where((publication) {
          bool matchesAnyField(String word, PublicationCard pub) {
            return pub.title.toLowerCase().contains(word) ||
                pub.journalTitle.toLowerCase().contains(word) ||
                pub.abstract.toLowerCase().contains(word) ||
                pub.licenseName.toLowerCase().contains(word) ||
                pub.authors.any(
                    (author) => author.family.toLowerCase().contains(word)) ||
                pub.authors
                    .any((author) => author.given.toLowerCase().contains(word));
          }

          if (_useAndFilter) {
            return keywords.every((word) => matchesAnyField(word, publication));
          } else {
            return keywords.any((word) => matchesAnyField(word, publication));
          }
        }).toList();
      }
      _sortFeed();
    });
  }

  Future<List<PublicationCard>> _getCachedFeed(
      BuildContext context, VoidCallback? onAbstractChanged) async {
    final cachedPublications = await dbHelper.getCachedPublications();

    return Future.wait(cachedPublications.map((item) async {
      return PublicationCard(
        key: ValueKey(item.doi),
        title: item.title,
        abstract: await AbstractHelper.buildAbstract(context, item.abstract),
        journalTitle: item.journalTitle,
        issn: item.issn,
        publishedDate: item.publishedDate,
        doi: item.doi,
        authors: item.authors,
        url: item.url,
        license: item.license,
        licenseName: item.licenseName,
        onAbstractChanged: onAbstractChanged,
        showHideBtn: true,
        onHide: _onAbstractChanged,
      );
    }).toList());
  }

  void _onAbstractChanged() async {
    final List<PublicationCard> cachedFeed =
        await _getCachedFeed(context, _onAbstractChanged);
    setState(() {
      _allFeed = List.from(cachedFeed);
    });

    if (_currentFeedName == 'Home') {
      setState(() {
        _activeFeed = List.from(_allFeed);
        _filterFeed(_filterController.text);
      });
    } else {
      await _applyStoredFilter();
    }

    _sortFeed();
    _feedStreamController.add(_filteredFeed);
  }

  void handleMenuButton(int item) async {
    switch (item) {
      case 0:
        showSortDialog(
          context: context,
          initialSortBy: sortBy,
          initialSortOrder: sortOrder,
          onSortByChanged: (int value) {
            setState(() {
              sortBy = value;
            });
            _sortFeed();
          },
          onSortOrderChanged: (int value) {
            setState(() {
              sortOrder = value;
            });
            _sortFeed();
          },
          sortByOptions: [
            AppLocalizations.of(context)!.datepublished,
            AppLocalizations.of(context)!.articletitle,
            AppLocalizations.of(context)!.journaltitle,
            AppLocalizations.of(context)!.firstauthfamname,
          ],
          sortOrderOptions: [
            AppLocalizations.of(context)!.ascending,
            AppLocalizations.of(context)!.descending,
          ],
        );
        break;
      case 1:
        final journals = await dbHelper.getAllJournals();
        // Split journals into followed and not followed (coming from saved queries)
        final followedJournals = journals
            .where((j) => j.dateFollowed != null)
            .map((j) => j.title)
            .toList();
        final unfollowedJournals = journals
            .where((j) => j.dateFollowed == null)
            .map((j) => j.title)
            .toList();

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return CustomizeFeedBottomSheet(
              followedJournals: followedJournals,
              moreJournals: unfollowedJournals,
              onApply: (String feedName, Set<String> journals, String include,
                  String exclude) {
                _applyAdvancedFilters(feedName, journals, include, exclude);
              },
            );
          },
        );
        break;

      case 2:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HiddenArticlesScreen()),
        );
        _onAbstractChanged();
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _filterController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchPlaceholder,
                  border: UnderlineInputBorder(),
                ),
              )
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _showFeedFiltersDialog,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DefaultTextStyle(
                          style: Theme.of(context).appBarTheme.titleTextStyle ??
                              Theme.of(context).textTheme.headlineSmall!,
                          child: Flexible(
                            child: Text(
                              _currentFeedName == 'Home'
                                  ? AppLocalizations.of(context)!.home
                                  : _currentFeedName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color:
                              Theme.of(context).appBarTheme.iconTheme?.color ??
                                  Theme.of(context).iconTheme.color,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        centerTitle: false,
        actions: [
          _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _filterController.clear(); // This restores the full feed
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
          IconButton(
            icon: Image.asset(
              'assets/icon/icon.png',
              width: 28,
              height: 28,
            ),
            onPressed: () {
              AppBarDropdownMenu.show(
                context: context,
                onSelected: (item) => handleMenuButton(item),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PublicationCard>>(
        stream: _feedStreamController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      AppLocalizations.of(context)!.buildingfeed,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  if (_currentJournalNames.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        AppLocalizations.of(context)!
                            .fetchingArticleFromJournal(
                                _currentJournalNames.toSet().length == 1
                                    ? _currentJournalNames[0]
                                    : _currentJournalNames.toSet().join(', ')),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            logger.severe("Home feed snapshot error.",
                snapshot.error.toString(), snapshot.stackTrace);
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          } else if (_allFeed.isEmpty) {
            // Show a message when allFeed is empty
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  AppLocalizations.of(context)!.homeFeedEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Show a message when filteredFeed is empty
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  AppLocalizations.of(context)!.filterResultsEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              cacheExtent: 1000.0,
              itemBuilder: (context, index) {
                return snapshot.data![index];
              },
            );
          }
        },
      ),
    );
  }

  void _applyAdvancedFilters(
      String feedName, Set<String> journals, String include, String exclude) {
    if (journals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorSelectOneJournal),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _currentFeedName = feedName;
      _activeFeed = _allFeed.where((pub) {
        final matchesJournal = journals.contains(pub.journalTitle);
        if (!matchesJournal) return false;

        final includeWords = include
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toList();
        final excludeWords = exclude
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toList();

        final content =
            '${pub.title} ${pub.abstract} ${pub.journalTitle}'.toLowerCase();

        final matchesInclude = includeWords.isEmpty
            ? true
            : includeWords.every((word) => content.contains(word));

        final matchesExclude = excludeWords.isEmpty
            ? true
            : excludeWords.every((word) => !content.contains(word));

        return matchesInclude && matchesExclude;
      }).toList();

      _filterFeed(_filterController.text);
      _sortFeed();
    });

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('lastSelectedFeed', feedName);
    });
  }

  Future<void> _applyStoredFilter() async {
    final filters = await dbHelper.getParsedFeedFilters();
    final match = filters.firstWhere(
      (f) => f.name == _currentFeedName,
      orElse: () => FeedFilter(
        id: 0,
        name: 'Home',
        include: '',
        exclude: '',
        journals: <String>{},
        dateCreated: '',
      ),
    );

    if (match.name != 'Home') {
      _applyAdvancedFilters(
          match.name, match.journals, match.include, match.exclude);
    }
  }

  @override
  void dispose() {
    _feedStreamController.close();
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _showFeedFiltersDialog() async {
    final db = DatabaseHelper();
    final List<FeedFilter> filters = await db.getParsedFeedFilters();

    final allFilters = [
      FeedFilter(
        id: 0,
        name: 'Home',
        include: '',
        exclude: '',
        journals: <String>{},
        dateCreated: '',
      ),
      ...filters,
    ];

    bool isEditing = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  minWidth: MediaQuery.of(context).size.width < 500
                      ? MediaQuery.of(context).size.width * 0.95
                      : 0,
                ),
                child: AlertDialog(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.selectFeed,
                          style: Theme.of(context).textTheme.titleLarge,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => isEditing = !isEditing),
                        child: Text(
                          isEditing
                              ? AppLocalizations.of(context)!.done
                              : AppLocalizations.of(context)!.edit,
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: allFilters.length,
                      itemBuilder: (context, index) {
                        final filter = allFilters[index];
                        return ListTile(
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  filter.name == 'Home'
                                      ? AppLocalizations.of(context)!.home
                                      : filter.name,
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                              if (isEditing && filter.name != 'Home') ...[
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    final journals = db.getAllJournals();
                                    journals.then((allJournals) {
                                      final followedJournals = allJournals
                                          .where((j) => j.dateFollowed != null)
                                          .map((j) => j.title)
                                          .toList();
                                      final unfollowedJournals = allJournals
                                          .where((j) => j.dateFollowed == null)
                                          .map((j) => j.title)
                                          .toList();

                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20)),
                                        ),
                                        builder: (context) {
                                          return CustomizeFeedBottomSheet(
                                            followedJournals: followedJournals,
                                            moreJournals: unfollowedJournals,
                                            initialName: filter.name,
                                            initialInclude: filter.include,
                                            initialExclude: filter.exclude,
                                            initialSelectedJournals:
                                                filter.journals,
                                            feedId: filter.id,
                                            onApply: (String feedName,
                                                Set<String> journals,
                                                String include,
                                                String exclude) {
                                              _applyAdvancedFilters(feedName,
                                                  journals, include, exclude);
                                            },
                                          );
                                        },
                                      );
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  onPressed: () async {
                                    await db.deleteFeedFilter(filter.id);
                                    Navigator.pop(context);

                                    // Reset to Home feed after deletion
                                    setState(() {
                                      _currentFeedName = 'Home';
                                      _activeFeed = List.from(_allFeed);
                                      _filteredFeed = List.from(_allFeed);
                                      _sortFeed();
                                      _filterController.clear();
                                    });

                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString(
                                        'lastSelectedFeed', 'Home');

                                    _showFeedFiltersDialog();
                                  },
                                ),
                              ],
                            ],
                          ),
                          onTap: !isEditing
                              ? () async {
                                  Navigator.pop(context);
                                  if (filter.name == 'Home') {
                                    setState(() {
                                      _currentFeedName = 'Home';
                                      _activeFeed = List.from(_allFeed);
                                      _filteredFeed = List.from(_allFeed);
                                      _sortFeed();
                                      _filterController.clear();
                                    });

                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString(
                                        'lastSelectedFeed', filter.name);
                                  } else {
                                    setState(() {
                                      _currentFeedName = filter.name;
                                    });
                                    _applyAdvancedFilters(
                                        filter.name,
                                        filter.journals,
                                        filter.include,
                                        filter.exclude);
                                  }
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
