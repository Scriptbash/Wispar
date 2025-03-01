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
  List<DownloadedCard> _downloadedArticles = [];
  bool _isLoading = true;

  int sortBy = 0; // Set the sort by option to Article title by default
  int sortOrder = 0; // Set the sort order to Ascending by default

  // Variables related to the filter bar in the appbar
  final TextEditingController _filterController = TextEditingController();
  List<DownloadedCard> _filteredDownloads = [];
  bool _useAndFilter = true;

  @override
  void initState() {
    super.initState();
    _fetchDownloadedArticles();

    _filterController.addListener(() {
      _filterDownloads(_filterController.text);
    });
  }

  Future<void> _fetchDownloadedArticles() async {
    final databaseHelper = DatabaseHelper();
    final articles = await databaseHelper.getDownloadedArticles();
    setState(() {
      _downloadedArticles = _sortDownloads(articles);
      _filteredDownloads = List.from(_downloadedArticles);
      _isLoading = false;
    });
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
        title: Container(
          height: 50.0,
          child: TextField(
            controller: _filterController,
            decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.filterDownloads,
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
                          _filterDownloads(_filterController.text);
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
                            title:
                                Text(AppLocalizations.of(context)!.sortorder),
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
          ),
        ),
        centerTitle: false,
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

  void handleMenuButton(int item) {
    switch (item) {
      case 0:
        showSortByDialog(
          context: context,
          initialSortBy: sortBy,
          onSortByChanged: (int value) {
            setState(() {
              sortBy = value;
              _downloadedArticles = _sortDownloads(_downloadedArticles);
              _filterDownloads(_filterController.text); // Apply filter again
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
                  _downloadedArticles = _sortDownloads(_downloadedArticles);
                  _filterDownloads(_filterController.text);
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

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }
}
