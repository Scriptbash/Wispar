import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/publication_card.dart';
import '../services/database_helper.dart';
import '../services/abstract_helper.dart';
import '../widgets/sortbydialog.dart';
import '../widgets/sortorderdialog.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<PublicationCard>> _favoriteArticles;
  int sortBy = 0; // Set the sort by option to Article title by default
  int sortOrder = 0; // Set the sort order to Ascending by default
  Map<String, String> abstractCache = {}; // Cache for abstracts

  @override
  void initState() {
    super.initState();
    _favoriteArticles = DatabaseHelper().getFavoriteArticles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(AppLocalizations.of(context)!.favorites),
        actions: [
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
            List<PublicationCard> favorites = snapshot.data!;
            List<PublicationCard> sortedFavorites = _sortFavorites(favorites);

            return ListView.builder(
              itemCount: sortedFavorites.length,
              itemBuilder: (context, index) {
                final publicationCard = sortedFavorites[index];

                // Check if the abstract is cached, if not fetch it
                String? cachedAbstract = abstractCache[publicationCard.doi];
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
                            child: Text('Error: ${abstractSnapshot.error}'));
                      } else if (!abstractSnapshot.hasData) {
                        return Center(child: Text('No abstract available'));
                      } else {
                        String formattedAbstract = abstractSnapshot.data!;

                        // Cache the abstract for future use
                        abstractCache[publicationCard.doi] = formattedAbstract;

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

  // Handles the sort by and sort order options
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
      _favoriteArticles = DatabaseHelper().getFavoriteArticles();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${publicationCard.title} ${AppLocalizations.of(context)!.favoriteremoved}'),
      ),
    );
  }
}
