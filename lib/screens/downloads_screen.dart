import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import '../widgets/downloaded_card.dart';
import '../services/database_helper.dart';
import '../widgets/sort_dialog.dart';
import '../services/logs_helper.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final logger = LogsService().logger;
  List<DownloadedCard> _downloadedArticles = [];
  bool _isLoading = true;

  int sortBy = 0; // Set the sort by option to Article title by default
  int sortOrder = 0; // Set the sort order to Ascending by default

  // Variables related to the filter bar in the appbar
  final TextEditingController _filterController = TextEditingController();
  List<DownloadedCard> _filteredDownloads = [];
  bool _useAndFilter = true;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _fetchDownloadedArticles();

    _filterController.addListener(() {
      _filterDownloads(_filterController.text);
    });
  }

  Future<void> _fetchDownloadedArticles() async {
    try {
      final databaseHelper = DatabaseHelper();
      final articles = await databaseHelper.getDownloadedArticles();
      setState(() {
        _downloadedArticles = _sortDownloads(articles);
        _filteredDownloads = List.from(_downloadedArticles);
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      logger.severe('Failed to load downloaded articles.', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorOccured)),
      );
    }
  }

  void _filterDownloads(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDownloads = List.from(_downloadedArticles);
      } else {
        List<String> keywords = query.toLowerCase().split(' ');

        _filteredDownloads = _downloadedArticles.where((article) {
          bool matchesAnyField(String word) {
            return article.publicationCard.title.toLowerCase().contains(word) ||
                article.publicationCard.journalTitle
                    .toLowerCase()
                    .contains(word);
          }

          if (_useAndFilter) {
            return keywords.every(matchesAnyField); // AND logic
          } else {
            return keywords.any(matchesAnyField); // OR logic
          }
        }).toList();
      }
    });
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
                  hintText: AppLocalizations.of(context)!.filterDownloads,
                  border: UnderlineInputBorder(),
                ),
              )
            : Text(AppLocalizations.of(context)!.downloads),
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
            onPressed: () => handleMenuButton(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _filteredDownloads.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _filterController.text.isEmpty
                          ? AppLocalizations.of(context)!.noDownloads
                          : AppLocalizations.of(context)!.filterResultsEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredDownloads.length,
                  itemBuilder: (context, index) {
                    final article = _filteredDownloads[index];
                    return DownloadedCard(
                      publicationCard: article.publicationCard,
                      pdfPath: article.pdfPath,
                      onDelete: () => _handleDelete(index),
                    );
                  },
                ),
    );
  }

  void _handleDelete(int index) {
    setState(() {
      _downloadedArticles.removeAt(index); // Remove the article from the list
      _filterDownloads(_filterController.text);
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
        AppLocalizations.of(context)!.datepublished,
      ],
      sortOrderOptions: [
        AppLocalizations.of(context)!.ascending,
        AppLocalizations.of(context)!.descending,
      ],
      onSortByChanged: (int value) {
        setState(() {
          sortBy = value;
          _downloadedArticles = _sortDownloads(_downloadedArticles);
          _filterDownloads(_filterController.text);
        });
      },
      onSortOrderChanged: (int value) {
        setState(() {
          sortOrder = value;
          _downloadedArticles = _sortDownloads(_downloadedArticles);
          _filterDownloads(_filterController.text);
        });
      },
    );
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

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }
}
