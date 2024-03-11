import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../downloaded_card.dart';
import '../services/database_helper.dart';

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
              onSelected: (item) => handleMenuButton(context, item),
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
        /*case 3:
          // Sort by Date published
          return a.publicationCard.dateDownloaded!.compareTo(b.publicationCard.dateDownloaded!);*/

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
      title: Text(AppLocalizations.of(context)!.sortby),
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
                Navigator.pop(context);
              },
              title: Text(AppLocalizations.of(context)!.articletitle),
            ),
            RadioListTile<int>(
              value: 1,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
                Navigator.pop(context);
              },
              title: Text(AppLocalizations.of(context)!.journaltitle),
            ),
            RadioListTile<int>(
              value: 2,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
                Navigator.pop(context);
              },
              title: Text(AppLocalizations.of(context)!.datepublished),
            ),
            /* RadioListTile<int>(
              value: 3,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
                Navigator.pop(context);
              },
              title: Text(AppLocalizations.of(context)!.datepublished),
            ),
            RadioListTile<int>(
              value: 4,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
                Navigator.pop(context);
              },
              title: Text(AppLocalizations.of(context)!.dateaddedtofavorites),
            ),*/
          ],
        ),
      ),
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
      title: Text(AppLocalizations.of(context)!.sortorder),
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
                Navigator.pop(context);
              },
              title: Text(AppLocalizations.of(context)!.ascending),
            ),
            RadioListTile<int>(
              value: 1,
              groupValue: selectedSortOrder,
              onChanged: (int? value) {
                setState(() {
                  selectedSortOrder = value!;
                  widget.onSortOrderChanged(selectedSortOrder);
                });
                Navigator.pop(context);
              },
              title: Text(AppLocalizations.of(context)!.descending),
            ),
          ],
        ),
      ),
    );
  }
}
