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
        title: Text(AppLocalizations.of(context)!.favorite),
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
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final publicationCard = snapshot.data![index];
                return PublicationCard(
                    title: publicationCard.title,
                    abstract: publicationCard.abstract,
                    journalTitle: publicationCard.journalTitle,
                    publishedDate: publicationCard.publishedDate,
                    doi: publicationCard.doi,
                    authors: publicationCard.authors,
                    onFavoriteChanged: () {
                      // Refresh the UI after removing the favorite
                      _removeFavorite(context, publicationCard);
                    });
              },
            );
          }
        },
      ),
    );
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
