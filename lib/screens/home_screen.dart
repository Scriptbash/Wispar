import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'settings_screen.dart';
import '../services/feed_api.dart';
import '../models/journal_entity.dart';
import '../models/crossref_journals_works_models.dart' as journalWorks;
import '../services/database_helper.dart';
import '../services/abstract_helper.dart';
import '../widgets/publication_card.dart';
import '../widgets/sortbydialog.dart';
import '../widgets/sortorderdialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final StreamController<List<PublicationCard>> _feedStreamController =
      StreamController<List<PublicationCard>>();

  int sortBy = 0; // Set the default sort by to published date
  int sortOrder = 1; // Set the default sort order to descending
  int fetchIntervalInHours = 6; // Default to 6 hours for API fetch
  String _currentJournalName = '';

  @override
  void initState() {
    super.initState();
    _loadFetchInterval();
    _buildAndStreamFeed();
  }

  Future<void> _loadFetchInterval() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fetchIntervalInHours = prefs.getInt('fetchInterval') ?? 6;
    });
  }

  Future<void> _buildAndStreamFeed() async {
    try {
      final followedJournals = await dbHelper.getJournals();
      final feedItems = await _buildFeed(followedJournals);
      _feedStreamController.add(feedItems);
    } catch (e) {
      _feedStreamController.addError(e);
    }
  }

  Future<List<PublicationCard>> _buildFeed(
      List<Journal> followedJournals) async {
    try {
      // Fetch cached publications
      List<PublicationCard> feedItems = await dbHelper.getCachedPublications();

      feedItems = await Future.wait(feedItems.map((item) async {
        return PublicationCard(
          title: item.title,
          abstract: await AbstractHelper.buildAbstract(context, item.abstract),
          journalTitle: item.journalTitle,
          issn: item.issn,
          publishedDate: item.publishedDate,
          doi: item.doi,
          authors: item.authors,
          url: item.url,
          license: item.license,
          licenseName: item.licenseName,
        );
      }).toList());

      // Check for journals that need updates
      List<String> journalsToUpdate =
          await _checkJournalsLastUpdated(followedJournals);

      if (feedItems.isEmpty || journalsToUpdate.isNotEmpty) {
        for (Journal journal in followedJournals) {
          if (journalsToUpdate.contains(journal.issn)) {
            setState(() {
              _currentJournalName = journal.title;
            });
            try {
              await dbHelper.updateJournalLastUpdated(journal.issn);

              // Fetch recent feed for the journal
              List<journalWorks.Item> recentFeed =
                  await FeedApi.getRecentFeed(journal.issn);

              List<PublicationCard> newCards =
                  await Future.wait(recentFeed.map((item) async {
                return PublicationCard(
                  title: item.title,
                  abstract: await AbstractHelper.buildAbstract(
                      context, item.abstract),
                  journalTitle: item.journalTitle,
                  issn: journal.issn,
                  publishedDate: item.publishedDate,
                  doi: item.doi,
                  authors: item.authors,
                  url: item.primaryUrl,
                  license: item.license,
                  licenseName: item.licenseName,
                );
              }).toList());

              feedItems.addAll(newCards);
            } catch (e) {
              debugPrint('Error fetching feed for ${journal.title}: $e');
            }
          }
        }

        // Cache the fetched publications
        for (PublicationCard item in feedItems) {
          await dbHelper.insertArticle(
              PublicationCard(
                title: item.title,
                abstract: item.abstract.isNotEmpty &&
                        item.abstract !=
                            AppLocalizations.of(context)!.abstractunavailable
                    ? item
                        .abstract // Use the abstract if it's not empty and not the fallback string
                    : '', // Otherwise, insert an empty string
                journalTitle: item.journalTitle,
                issn: item.issn,
                publishedDate: item.publishedDate,
                doi: item.doi,
                authors: item.authors,
                url: item.url,
                license: item.license,
                licenseName: item.licenseName,
              ),
              isCached: true);
        }
      }

      // Sort publications
      feedItems.sort((a, b) {
        switch (sortBy) {
          case 0:
            return a.publishedDate!.compareTo(b.publishedDate!);
          case 1:
            return a.title.compareTo(b.title);
          case 2:
            return a.journalTitle.compareTo(b.journalTitle);
          case 3:
            return a.authors[0].family.compareTo(b.authors[0].family);
          default:
            return 0;
        }
      });

      // Reverse feed items if sortOrder is descending
      if (sortOrder == 1) {
        feedItems = feedItems.reversed.toList();
      }

      return feedItems;
    } catch (e) {
      debugPrint('Error in _buildFeed: $e');
      return [];
    }
  }

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
                fetchIntervalInHours) {
          journalsToUpdate.add(journal.issn);
        }
      }
    }

    return journalsToUpdate;
  }

  void handleMenuButton(int item) {
    switch (item) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (context) => const SettingsScreen()),
        );
        break;
      case 1:
        showSortByDialog(
          context: context,
          initialSortBy: sortBy,
          onSortByChanged: (int value) {
            setState(() {
              sortBy = value;
            });
            _buildAndStreamFeed();
          },
          sortOptions: [
            AppLocalizations.of(context)!.datepublished,
            AppLocalizations.of(context)!.articletitle,
            AppLocalizations.of(context)!.journaltitle,
            AppLocalizations.of(context)!.firstauthfamname,
          ],
        );
        break;
      case 2:
        showDialog(
          context: context,
          builder: (context) => SortOrderDialog(
            initialSortOrder: sortOrder,
            sortOrderOptions: [
              AppLocalizations.of(context)!.ascending,
              AppLocalizations.of(context)!.descending,
            ],
            onSortOrderChanged: (int value) {
              setState(() {
                sortOrder = value;
              });
              _buildAndStreamFeed();
            },
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.home),
        actions: <Widget>[
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert),
            onSelected: (item) => handleMenuButton(item),
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
      body: StreamBuilder<List<PublicationCard>>(
        stream: _feedStreamController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.buildingfeed),
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  if (_currentJournalName.isNotEmpty)
                    Text(AppLocalizations.of(context)!
                        .fetchingArticleFromJournal(_currentJournalName))
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.homeFeedEmpty),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return snapshot.data![index];
              },
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _feedStreamController.close();
    super.dispose();
  }
}
