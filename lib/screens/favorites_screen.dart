import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/crossref_journals_works_models.dart';
import '../publication_card.dart';
import '../services/database_helper.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<PublicationCard>> _favoriteArticles;
  int sortBy = 0; // Set the sort by option to Article title by default
  int sortOrder = 0; // Set the sort order to Ascending by default

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
            onSelected: (item) => handleMenuButton(context, item),
            itemBuilder: (context) => [
              PopupMenuItem<int>(value: 0, child: Text('Sort by')),
              PopupMenuItem<int>(value: 1, child: Text('Sort order')),
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
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.nofavorites1),
                  Icon(Icons.favorite_border),
                  Text(AppLocalizations.of(context)!.nofavorites2),
                ],
              ),
            );
          } else {
            List<PublicationCard> favorites = snapshot.data!;
            List<PublicationCard> sortedFavorites = _sortFavorites(favorites);

            return ListView.builder(
              itemCount: sortedFavorites.length,
              itemBuilder: (context, index) {
                final publicationCard = sortedFavorites[index];
                return PublicationCard(
                  title: publicationCard.title,
                  abstract: publicationCard.abstract,
                  journalTitle: publicationCard.journalTitle,
                  publishedDate: publicationCard.publishedDate,
                  doi: publicationCard.doi,
                  authors: publicationCard.authors,
                  dateLiked: publicationCard.dateLiked,
                  onFavoriteChanged: () {
                    // Refresh the UI after removing the favorite
                    _removeFavorite(context, publicationCard);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  void _handleSortByChanged(int value) {
    setState(() {
      sortBy = value;
    });
  }

  void _handleSortOrderChanged(int value) {
    setState(() {
      sortOrder = value;
    });
  }

  void handleMenuButton(BuildContext context, int item) {
    switch (item) {
      case 0:
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return SortByDialog(
              initialSortBy: sortBy,
              onSortByChanged: _handleSortByChanged,
            );
          },
        );
        break;
      case 1:
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return SortOrderDialog(
              initialSortOrder: sortOrder,
              onSortOrderChanged: _handleSortOrderChanged,
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

class SortByDialog extends StatefulWidget {
  final int initialSortBy;
  final ValueChanged<int> onSortByChanged;

  SortByDialog({required this.initialSortBy, required this.onSortByChanged});

  @override
  _SortByDialogState createState() => _SortByDialogState();
}

class _SortByDialogState extends State<SortByDialog> {
  late int selectedSortBy;

  @override
  void initState() {
    super.initState();
    selectedSortBy = widget.initialSortBy;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sort by'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            RadioListTile<int>(
              value: 0,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
              },
              title: Text('Article title'),
            ),
            RadioListTile<int>(
              value: 1,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
              },
              title: Text('Journal title'),
            ),
            RadioListTile<int>(
              value: 2,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
              },
              title: Text('First author family name'),
            ),
            RadioListTile<int>(
              value: 3,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
              },
              title: Text('Date published'),
            ),
            RadioListTile<int>(
              value: 4,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
              },
              title: Text('Date added to favorites'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('OK'),
        ),
      ],
    );
  }
}

class SortOrderDialog extends StatefulWidget {
  final int initialSortOrder;
  final ValueChanged<int> onSortOrderChanged;

  SortOrderDialog(
      {required this.initialSortOrder, required this.onSortOrderChanged});

  @override
  _SortOrderDialogState createState() => _SortOrderDialogState();
}

class _SortOrderDialogState extends State<SortOrderDialog> {
  late int selectedSortOrder;

  @override
  void initState() {
    super.initState();
    selectedSortOrder = widget.initialSortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sort order'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            RadioListTile<int>(
              value: 0,
              groupValue: selectedSortOrder,
              onChanged: (int? value) {
                setState(() {
                  selectedSortOrder = value!;
                  widget.onSortOrderChanged(selectedSortOrder);
                });
              },
              title: Text('Ascending'),
            ),
            RadioListTile<int>(
              value: 1,
              groupValue: selectedSortOrder,
              onChanged: (int? value) {
                setState(() {
                  selectedSortOrder = value!;
                  widget.onSortOrderChanged(selectedSortOrder);
                });
              },
              title: Text('Descending'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('OK'),
        ),
      ],
    );
  }
}
