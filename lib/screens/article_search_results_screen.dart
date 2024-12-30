import 'package:flutter/material.dart';
import '../models/crossref_journals_works_models.dart';
import '../widgets/publication_card.dart';
import '../models/crossref_journals_works_models.dart' as journalsWorks;

class ArticleSearchResultsScreen extends StatelessWidget {
  final List<journalsWorks.Item> searchResults;

  const ArticleSearchResultsScreen({
    Key? key,
    required this.searchResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
      ),
      body: searchResults.isNotEmpty
          ? ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final item = searchResults[index];
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
                );
              },
            )
          : Center(
              child: Text('No results found'),
            ),
    );
  }
}
