import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/widgets/publication_card/publication_card.dart';
import 'package:wispar/screens/publication_card_settings_screen.dart';
import 'package:wispar/services/database_helper.dart';
import 'package:wispar/services/abstract_helper.dart';
import 'package:wispar/widgets/sort_dialog.dart';
import 'package:wispar/services/logs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  FavoritesScreenState createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  final logger = LogsService().logger;
  late Future<List<PublicationCard>> _favoriteArticles;
  int sortBy = 0; // Set the sort by option to Article title by default
  int sortOrder = 0; // Set the sort order to Ascending by default
  Map<String, String> abstractCache = {}; // Cache for abstracts

  // Variables related to the filter bar in the appbar
  final TextEditingController _filterController = TextEditingController();
  List<PublicationCard> _allFavorites = [];
  List<PublicationCard> _filteredFavorites = [];
  final ScrollController _scrollController = ScrollController();

  bool _useAndFilter = true;
  bool _showSearchBar = false;

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
    _favoriteArticles = _loadAllData();

    _filterController.addListener(() {
      _filterFeed(_filterController.text);
    });
  }

  Future<List<PublicationCard>> _loadAllData() async {
    await _loadCardPreferences();
    return _loadFavoriteArticles();
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

  Future<List<PublicationCard>> _loadFavoriteArticles() async {
    try {
      List<PublicationCard> favorites =
          await DatabaseHelper().getFavoriteArticles();

      for (var card in favorites) {
        String formattedAbstract =
            await AbstractHelper.buildAbstract(context, card.abstract);
        abstractCache[card.doi] = formattedAbstract;
      }

      setState(() {
        _allFavorites = favorites;
        _filteredFavorites = _sortFavorites(favorites);
      });
      return favorites;
    } catch (e, stackTrace) {
      logger.severe('Failed to load favorite articles.', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorOccured)),
      );
      return [];
    }
  }

  // Filters the feed using the filter bar
  void _filterFeed(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFavorites = List.from(_allFavorites);
      } else {
        List<String> keywords = query.toLowerCase().split(' ');

        _filteredFavorites = _allFavorites.where((publication) {
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
            return keywords.every(
                (word) => matchesAnyField(word, publication)); // AND logic
          } else {
            return keywords
                .any((word) => matchesAnyField(word, publication)); // OR logic
          }
        }).toList();
      }
      _filteredFavorites = _sortFavorites(_filteredFavorites);
    });
  }

  List<PublicationCard> _sortFavorites(List<PublicationCard> favorites) {
    favorites.sort((a, b) {
      String trimString(String input) =>
          input.trim().replaceAll(RegExp(r'\s+'), '');

      switch (sortBy) {
        case 0:
          return trimString(a.title.toLowerCase())
              .compareTo(trimString(b.title.toLowerCase()));
        case 1:
          return trimString(a.journalTitle.toLowerCase())
              .compareTo(trimString(b.journalTitle.toLowerCase()));
        case 2:
          return a.authors[0].family
              .toLowerCase()
              .compareTo(b.authors[0].family.toLowerCase());
        case 3:
          return a.publishedDate!.compareTo(b.publishedDate!);
        case 4:
          return a.dateLiked!.compareTo(b.dateLiked!);
        default:
          return 0;
      }
    });

    if (sortOrder == 1) {
      favorites = favorites.reversed.toList();
    }

    return favorites;
  }

  Future<void> _removeFavorite(
      BuildContext context, PublicationCard publicationCard) async {
    await DatabaseHelper().removeFavorite(publicationCard.doi);

    setState(() {
      _allFavorites.removeWhere((p) => p.doi == publicationCard.doi);
      _filteredFavorites.removeWhere((p) => p.doi == publicationCard.doi);
      abstractCache.remove(publicationCard.doi);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${publicationCard.title} ${AppLocalizations.of(context)!.favoriteremoved}'),
      ),
    );
  }

  Future<void> _updateAbstract() async {
    List<PublicationCard> currentFavorites =
        await DatabaseHelper().getFavoriteArticles();

    for (var card in currentFavorites) {
      String formattedAbstract =
          await AbstractHelper.buildAbstract(context, card.abstract);
      abstractCache[card.doi] = formattedAbstract;
    }
    setState(() {
      _allFavorites = currentFavorites;
      _filterFeed(_filterController.text);
    });
  }

  void handleMenuButton() {
    showSortDialog(
      context: context,
      initialSortBy: sortBy,
      initialSortOrder: sortOrder,
      sortByOptions: [
        AppLocalizations.of(context)!.articletitle,
        AppLocalizations.of(context)!.journaltitle,
        AppLocalizations.of(context)!.firstauthfamname,
        AppLocalizations.of(context)!.datepublished,
        AppLocalizations.of(context)!.dateaddedtofavorites,
      ],
      sortOrderOptions: [
        AppLocalizations.of(context)!.ascending,
        AppLocalizations.of(context)!.descending,
      ],
      onSortByChanged: (int value) {
        setState(() {
          sortBy = value;
        });
        _filterFeed(_filterController.text);
      },
      onSortOrderChanged: (int value) {
        setState(() {
          sortOrder = value;
        });
        _filterFeed(_filterController.text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar
            ? TextField(
                controller: _filterController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.filterFavorites,
                  border: UnderlineInputBorder(),
                ),
              )
            : Text(AppLocalizations.of(context)!.favorites),
        actions: [
          if (_showSearchBar)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _showSearchBar = false;
                  _filterController.clear();
                });
              },
            )
          else
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _showSearchBar = true;
                });
              },
            ),
          IconButton(
            icon: Icon(Icons.swap_vert),
            onPressed: handleMenuButton,
          ),
        ],
      ),
      body: FutureBuilder<List<PublicationCard>>(
        future: _favoriteArticles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  AppLocalizations.of(context)!.noFavorites,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            );
          } else {
            return LayoutBuilder(
              builder: (context, constraints) {
                final spacing = 1.0;
                final minCardWidth = 400.0;
                int columns = (constraints.maxWidth / minCardWidth).floor();
                columns = columns > 0 ? columns : 1;

                final totalSpacing = (columns + 1) * spacing;
                final cardWidth =
                    (constraints.maxWidth - totalSpacing) / columns;

                return SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 1.0),
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: _filteredFavorites.map((publicationCard) {
                      String cachedAbstract =
                          abstractCache[publicationCard.doi] ??
                              publicationCard.abstract;

                      final cardWidget = PublicationCard(
                        key: ValueKey(publicationCard.doi),
                        title: publicationCard.title,
                        abstract: cachedAbstract,
                        journalTitle: publicationCard.journalTitle,
                        issn: publicationCard.issn,
                        publishedDate: publicationCard.publishedDate,
                        doi: publicationCard.doi,
                        authors: publicationCard.authors,
                        url: publicationCard.url,
                        license: publicationCard.license,
                        licenseName: publicationCard.licenseName,
                        dateLiked: publicationCard.dateLiked,
                        swipeLeftAction: _swipeLeftAction,
                        swipeRightAction: _swipeRightAction,
                        showJournalTitle: _showJournalTitle,
                        showPublicationDate: _showPublicationDate,
                        showAuthorNames: _showAuthorNames,
                        showLicense: _showLicense,
                        showOptionsMenu: _showOptionsMenu,
                        showFavoriteButton: _showFavoriteButton,
                        onFavoriteChanged: () {
                          _removeFavorite(context, publicationCard);
                        },
                        onAbstractChanged: _updateAbstract,
                      );

                      return SizedBox(width: cardWidth, child: cardWidget);
                    }).toList(),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _filterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
