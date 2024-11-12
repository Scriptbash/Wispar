import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/downloaded_card.dart';
import '../services/database_helper.dart';
import '../widgets/sortbydialog.dart';
import '../widgets/sortorderdialog.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late Future<List<DownloadedCard>> _downloadedArticlesFuture;
  int sortBy = 0; // Set the sort by option to Article title by default
  int sortOrder = 0; // Set the sort order to Ascending by default

  @override
  void initState() {
    super.initState();
    _downloadedArticlesFuture = getDownloadedArticles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: false,
          title: Text(AppLocalizations.of(context)!.downloads),
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
            )
          ]),
      body: Center(
        child: FutureBuilder<List<DownloadedCard>>(
          future: _downloadedArticlesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              final downloadedArticles = snapshot.data!;
              if (downloadedArticles.isEmpty) {
                return Text('You do not have any downloads.');
              } else {
                List<DownloadedCard> downloads = snapshot.data!;
                List<DownloadedCard> sortedDownloads =
                    _sortDownloads(downloads);
                return ListView.builder(
                  itemCount: sortedDownloads.length,
                  itemBuilder: (context, index) {
                    return sortedDownloads[index];
                  },
                );
              }
            } else {
              return Text('No downloaded articles found.');
            }
          },
        ),
      ),
    );
  }

  Future<List<DownloadedCard>> getDownloadedArticles() async {
    final databaseHelper = DatabaseHelper();

    return await databaseHelper.getDownloadedArticles();
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
            AppLocalizations.of(context)!.datepublished,
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

  List<DownloadedCard> _sortDownloads(List<DownloadedCard> downloads) {
    downloads.sort((a, b) {
      String trimString(String input) {
        return input.trim().replaceAll(RegExp(r'\s+'), '');
      }

      switch (sortBy) {
        case 0:
          // Sort by Article title
          return trimString(a.publicationCard.title.toLowerCase())
              .compareTo(trimString(b.publicationCard.title.toLowerCase()));
        case 1:
          // Sort by Journal title
          return trimString(a.publicationCard.journalTitle.toLowerCase())
              .compareTo(
                  trimString(b.publicationCard.journalTitle.toLowerCase()));
        case 2:
          // Sort by Date published
          return a.publicationCard.publishedDate!
              .compareTo(b.publicationCard.publishedDate!);
        default:
          return 0;
      }
    });

    // Reverse the order if sortOrder is Descending
    if (sortOrder == 1) {
      downloads = downloads.reversed.toList();
    }

    return downloads;
  }
}
