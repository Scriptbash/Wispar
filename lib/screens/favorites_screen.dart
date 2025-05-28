import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import '../widgets/publication_card.dart';
import '../services/database_helper.dart';
import '../services/abstract_helper.dart';
import '../widgets/sortbydialog.dart';
import '../widgets/sortorderdialog.dart';
import '../services/logs_helper.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final logger = LogsService().logger;
  late Future<List<PublicationCard>> _favoriteArticles;
  late ScrollController _scrollController;
  int sortBy = 0; // Set the sort by option to Article title by default
  int sortOrder = 0; // Set the sort order to Ascending by default
  Map<String, String> abstractCache = {}; // Cache for abstracts

  // Variables related to the filter bar in the appbar
  final TextEditingController _filterController = TextEditingController();
  List<PublicationCard> _allFavorites = [];
  List<PublicationCard> _filteredFavorites = [];

  bool _useAndFilter = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _favoriteArticles = _loadFavoriteArticles();

    _filterController.addListener(() {
      _filterFeed(_filterController.text);
    });
  }

  Future<List<PublicationCard>> _loadFavoriteArticles() async {
    try {
      final double previousOffset = _scrollController.hasClients
          ? _scrollController.offset
          : 0; // Save scroll position
      List<PublicationCard> favorites =
          await DatabaseHelper().getFavoriteArticles();
      setState(() {
        _allFavorites = favorites;
        _filteredFavorites = _sortFavorites(favorites); // Apply sorting
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(previousOffset); // Restore scroll position
        }
      });
      return favorites;
    } catch (e, stackTrace) {
      logger.severe('Failed to load favorite articles.', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToLoadFavorites)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 50.0,
          child: TextField(
            controller: _filterController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.filterFavorites,
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                    color: Color.fromARGB(31, 148, 147, 147), width: 0.0),
                borderRadius: BorderRadius.circular(30.0),
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(
                    color: Color.fromARGB(31, 148, 147, 147), width: 0.0),
                borderRadius: BorderRadius.circular(30.0),
              ),
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Color.fromARGB(31, 148, 147, 147),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _useAndFilter = !_useAndFilter;
                        _filterFeed(_filterController.text);
                      });
                    },
                    child: Text(
                      _useAndFilter ? 'AND' : 'OR',
                    ),
                  ),
                  PopupMenuButton<int>(
                    icon: Icon(Icons.more_vert),
                    onSelected: (item) => handleMenuButton(item),
                    itemBuilder: (context) => [
                      PopupMenuItem<int>(
                        value: 0,
                        child: ListTile(
                          leading: Icon(Icons.sort),
                          title: Text(AppLocalizations.of(context)!.sortby),
                        ),
                      ),
                      PopupMenuItem<int>(
                        value: 1,
                        child: ListTile(
                          leading: Icon(Icons.sort_by_alpha),
                          title: Text(AppLocalizations.of(context)!.sortorder),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        centerTitle: false,
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
            return _filteredFavorites.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        AppLocalizations.of(context)!.filterResultsEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredFavorites.length,
                    itemBuilder: (context, index) {
                      final publicationCard = _filteredFavorites[index];

                      // Check if the abstract is cached, if not fetch it
                      String? cachedAbstract =
                          abstractCache[publicationCard.doi];
                      if (cachedAbstract != null) {
                        return PublicationCard(
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
                          onAbstractChanged: () {
                            _updateAbstract();
                          },
                        );
                      } else {
                        // Use the AbstractHelper to get the formatted abstract
                        return FutureBuilder<String>(
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

                              // Cache the abstract for future use
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
                                onAbstractChanged: () {
                                  _updateAbstract();
                                },
                              );
                            }
                          },
                        );
                      }
                    },
                  );
          }
        },
      ),
    );
  }

  void handleMenuButton(int item) {
    switch (item) {
      case 0:
        showSortByDialog(
          context: context,
          initialSortBy: sortBy,
          onSortByChanged: (int value) {
            setState(() {
              sortBy = value;
            });
            _filterFeed(_filterController.text);
          },
          sortOptions: [
            AppLocalizations.of(context)!.articletitle,
            AppLocalizations.of(context)!.journaltitle,
            AppLocalizations.of(context)!.firstauthfamname,
            AppLocalizations.of(context)!.datepublished,
            AppLocalizations.of(context)!.dateaddedtofavorites,
          ],
        );
        break;
      case 1:
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return SortOrderDialog(
              initialSortOrder: sortOrder,
              sortOrderOptions: [
                AppLocalizations.of(context)!.ascending,
                AppLocalizations.of(context)!.descending,
              ],
              onSortOrderChanged: (int value) {
                setState(() {
                  sortOrder = value;
                });
                _filterFeed(_filterController.text);
              },
            );
          },
        );
        break;
    }
  }

  List<PublicationCard> _sortFavorites(List<PublicationCard> favorites) {
    favorites.sort((a, b) {
      String trimString(String input) {
        return input.trim().replaceAll(RegExp(r'\s+'), '');
      }

      switch (sortBy) {
        case 0:
          // Sort by Article title
          return trimString(a.title.toLowerCase())
              .compareTo(trimString(b.title.toLowerCase()));
        case 1:
          // Sort by Journal title
          return trimString(a.journalTitle.toLowerCase())
              .compareTo(trimString(b.journalTitle.toLowerCase()));
        case 2:
          // Sort by First author name
          return (a.authors[0].family.toLowerCase())
              .compareTo((b.authors[0].family.toLowerCase()));
        case 3:
          // Sort by Date published
          return a.publishedDate!.compareTo(b.publishedDate!);
        case 4:
          // Sort by Date added to favorites
          return a.dateLiked!.compareTo(b.dateLiked!);
        default:
          return 0;
      }
    });

    // Reverse the order if sortOrder is Descending
    if (sortOrder == 1) {
      favorites = favorites.reversed.toList();
    }

    return favorites;
  }

  Future<void> _removeFavorite(
      BuildContext context, PublicationCard publicationCard) async {
    await DatabaseHelper().removeFavorite(publicationCard.doi);
    // Refresh the UI after removing the favorite
    setState(() {
      _favoriteArticles = _loadFavoriteArticles();
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

  @override
  void dispose() {
    _filterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
