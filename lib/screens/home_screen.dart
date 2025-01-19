import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'settings_screen.dart';
import '../services/database_helper.dart';
import '../services/feed_service.dart';
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

  final FeedService _feedService = FeedService();

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
      final journalsToUpdate = await _feedService.checkJournalsToUpdate(
          followedJournals, fetchIntervalInHours);

      if (mounted && journalsToUpdate.isNotEmpty) {
        await _feedService.updateFeed(
          context,
          followedJournals,
          (String journalName) {
            if (mounted) {
              setState(() {
                _currentJournalName = journalName;
              });
            }
          },
        );
      }

      if (mounted) {
        final List<PublicationCard> cachedFeed =
            await _feedService.getCachedFeed(context);

        // Sort publications
        List<PublicationCard> sortedFeed = List.from(cachedFeed);
        sortedFeed.sort((a, b) {
          switch (sortBy) {
            case 0: // Sort by published date
              return a.publishedDate!.compareTo(b.publishedDate!);
            case 1: // Sort by title
              return a.title.compareTo(b.title);
            case 2: // Sort by journal title
              return a.journalTitle.compareTo(b.journalTitle);
            case 3: // Sort by first author's family name
              return a.authors[0].family.compareTo(b.authors[0].family);
            default:
              return 0;
          }
        });

        // Reverse the list if sortOrder is descending
        if (sortOrder == 1) {
          sortedFeed = sortedFeed.reversed.toList();
        }

        _feedStreamController.add(sortedFeed);
      }
    } catch (e) {
      if (mounted) {
        _feedStreamController.addError(e);
      }
    }
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
