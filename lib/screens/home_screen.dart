import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'settings_screen.dart';
import '../services/feed_api.dart';
import '../models/crossref_journals_works_models.dart' as journalWorks;
import '../services/database_helper.dart';
import '../publication_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  DatabaseHelper dbHelper = DatabaseHelper();

  int sortBy = 0; // Set the default sort by to published date
  int sortOrder = 1; // Set the default sort order to descending

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(AppLocalizations.of(context)!.home),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            //tooltip: 'Settings',
            onPressed: () {
              //_openSettingsScreen(context);
            },
          ),
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert),
            onSelected: (item) => handleMenuButton(context, item),
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 0,
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text(AppLocalizations.of(context)!.settings),
                ),
              ),
              PopupMenuItem<int>(
                value: 1,
                child: ListTile(
                  leading: Icon(Icons.sort),
                  title: Text(AppLocalizations.of(context)!.sortby),
                ),
              ),
              PopupMenuItem<int>(
                value: 2,
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
        future: _getRecentFeedForFollowedJournals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.buildingfeed),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: AppLocalizations.of(context)!.nopublication1,
                        ),
                        WidgetSpan(
                          child: Icon(Icons.library_books_outlined),
                        ),
                        TextSpan(
                          text: AppLocalizations.of(context)!.nopublication2,
                        ),
                        WidgetSpan(
                          child: Icon(Icons.search),
                        ),
                        TextSpan(
                          text: AppLocalizations.of(context)!.nopublication3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                return item;
              },
            );
          }
        },
      ),
    );
  }

  Future<List<PublicationCard>> _getRecentFeedForFollowedJournals() async {
    try {
      // Fetch followed journals from the database
      List<Journal> followedJournals = await dbHelper.getJournals();

      // Get the cache publications
      List<PublicationCard> feedItems = await dbHelper.getCachedPublications();

      // Check if journals need to be updated
      List<String> journalsToUpdate =
          await _checkJournalsLastUpdated(followedJournals);

      // Sort publications
      feedItems.sort((a, b) {
        switch (sortBy) {
          case 0: // Sort by Published date
            return a.publishedDate!.compareTo(b.publishedDate!);
          case 1: // Sort by Article title
            return a.title.compareTo(b.title);
          case 2: // Sort by Journal Title
            return a.journalTitle.compareTo(b.journalTitle);
          case 3: // Sort by first author family name
            return a.authors[0].family.compareTo(b.authors[0].family);
          default:
            return 0;
        }
      });

      // Apply sortOrder
      if (sortOrder == 1) {
        feedItems = feedItems.reversed.toList(); // Descending order
      }

      // Check if there are new journals since the last API call
      //bool shouldForceApiCall = await _checkForNewJournals(followedJournals);

      // If the cache is empty or there are new journals, fetch recent feed from the API
      if (feedItems.isEmpty || journalsToUpdate.isNotEmpty) {
        //feedItems = [];
        for (Journal journal in followedJournals) {
          // Only fetch from the API if the journal needs an update
          if (journalsToUpdate.contains(journal.issn)) {
            try {
              await dbHelper.updateJournalLastUpdated(journal.issn);
              List<journalWorks.Item> recentFeed =
                  await FeedApi.getRecentFeed(journal.issn);

              List<PublicationCard> cards = recentFeed.map((item) {
                return PublicationCard(
                  title: item.title,
                  abstract: item.abstract,
                  journalTitle: item.journalTitle,
                  issn: journal.issn,
                  publishedDate: item.publishedDate,
                  doi: item.doi,
                  authors: item.authors,
                  url: item.primaryUrl,
                  license: item.license,
                  licenseName: item.licenseName,
                );
              }).toList();

              feedItems.addAll(cards);
              feedItems = feedItems
                  .where((item) =>
                      item.title.isNotEmpty && item.authors.isNotEmpty)
                  .toList();
            } catch (e) {
              print('Error fetching recent feed for ${journal.title}: $e');
            }
          }
        }

        // Cache the fetched publications
        // await dbHelper.clearCachedPublications();
        for (PublicationCard item in feedItems) {
          await dbHelper.insertArticle(item, isCached: true);
          //await dbHelper.insertCachedPublication(item);
        }
      }
      return feedItems;
    } catch (e) {
      print('Error in _getRecentFeedForFollowedJournals: $e');
      return [];
    }
  }

  /*Future<bool> _checkForNewJournals(List<Journal> followedJournals) async {
    try {
      // Get the timestamp of the last API call
      DateTime? lastApiCallTimestamp = await dbHelper.getLastApiCallTimestamp();
      // Check if more than 6 hours have passed since the last API call
      return DateTime.now().difference(lastApiCallTimestamp).inHours >= 6;
    } catch (e) {
      print('Error in _checkForNewJournals: $e');
      return false;
    }
  }*/

  Future<List<String>> _checkJournalsLastUpdated(
      List<Journal> followedJournals) async {
    final db = await dbHelper.database;
    List<String> journalsToUpdate = [];

    for (Journal journal in followedJournals) {
      List<Map<String, dynamic>> result = await db.query(
        'journals',
        columns: ['issn', 'lastUpdated'],
        where: 'issn = ?',
        whereArgs: [journal.issn],
      );

      if (result.isNotEmpty) {
        String? lastUpdated = result.first['lastUpdated'] as String?;

        if (lastUpdated == null ||
            DateTime.now().difference(DateTime.parse(lastUpdated)).inHours >=
                6) {
          journalsToUpdate.add(result.first['issn'] as String);
        }
      }
    }

    return journalsToUpdate;
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
        _openSettingsScreen(context);
        break;
      case 1:
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
      case 2:
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
}

_openSettingsScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return const SettingsScreen();
      },
    ),
  );
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
              title: Text(AppLocalizations.of(context)!.datepublished),
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
              title: Text(AppLocalizations.of(context)!.articletitle),
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
              title: Text(AppLocalizations.of(context)!.journaltitle),
            ),
            RadioListTile<int>(
              value: 3,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
                Navigator.pop(context);
              },
              title: Text(AppLocalizations.of(context)!.firstauthfamname),
            ),
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
