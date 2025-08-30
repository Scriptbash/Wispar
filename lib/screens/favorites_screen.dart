import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import '../widgets/publication_card.dart';
import '../services/database_helper.dart';
import '../services/abstract_helper.dart';
import '../widgets/sort_dialog.dart';
import '../services/logs_helper.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final logger = LogsService().logger;
  late Future<List<PublicationCard>> _favoriteArticles;
  int sortBy = 0; // Set the sort by option to Article title by default
  int sortOrder = 0; // Set the sort order to Ascending by default
  Map<String, String> abstractCache = {}; // Cache for abstracts

  // Variables related to the filter bar in the appbar
  final TextEditingController _filterController = TextEditingController();
  List<PublicationCard> _allFavorites = [];
  List<PublicationCard> _filteredFavorites = [];

  bool _useAndFilter = true;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _favoriteArticles = _loadFavoriteArticles();

    _filterController.addListener(() {
      _filterFeed(_filterController.text);
    });
  }

  Future<List<PublicationCard>> _loadFavoriteArticles() async {
    try {
      List<PublicationCard> favorites =
          await DatabaseHelper().getFavoriteArticles();
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
    setState(() {
      abstractCache = {};
      _favoriteArticles = _loadFavoriteArticles();
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
                final spacing = 8.0;
                final minCardWidth = 400.0;
                int columns = (constraints.maxWidth / minCardWidth).floor();
                columns = columns > 0 ? columns : 1;

                final totalSpacing = (columns + 1) * spacing;
                final cardWidth =
                    (constraints.maxWidth - totalSpacing) / columns;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(spacing),
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: _filteredFavorites.map((publicationCard) {
                      Widget cardWidget;

                      String? cachedAbstract =
                          abstractCache[publicationCard.doi];
                      if (cachedAbstract != null) {
                        cardWidget = PublicationCard(
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
                          onFavoriteChanged: () {
                            _removeFavorite(context, publicationCard);
                          },
                          onAbstractChanged: _updateAbstract,
                        );
                      } else {
                        cardWidget = FutureBuilder<String>(
                          future: AbstractHelper.buildAbstract(
                              context, publicationCard.abstract),
                          builder: (context, abstractSnapshot) {
                            if (abstractSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (abstractSnapshot.hasError) {
                              return Center(
                                  child:
                                      Text('Error: ${abstractSnapshot.error}'));
                            } else if (!abstractSnapshot.hasData) {
                              return Center(
                                  child: Text('No abstract available'));
                            } else {
                              String formattedAbstract = abstractSnapshot.data!;
                              abstractCache[publicationCard.doi] =
                                  formattedAbstract;

                              return PublicationCard(
                                title: publicationCard.title,
                                abstract: formattedAbstract,
                                journalTitle: publicationCard.journalTitle,
                                issn: publicationCard.issn,
                                publishedDate: publicationCard.publishedDate,
                                doi: publicationCard.doi,
                                authors: publicationCard.authors,
                                url: publicationCard.url,
                                license: publicationCard.license,
                                licenseName: publicationCard.licenseName,
                                dateLiked: publicationCard.dateLiked,
                                onFavoriteChanged: () {
                                  _removeFavorite(context, publicationCard);
                                },
                                onAbstractChanged: _updateAbstract,
                              );
                            }
                          },
                        );
                      }

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
    super.dispose();
  }
}
