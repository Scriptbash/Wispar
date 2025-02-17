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

  // Variables related to the filter bar in the appbar
  final TextEditingController _filterController = TextEditingController();
  List<PublicationCard> _allFeed = [];
  List<PublicationCard> _filteredFeed = [];

  final FeedService _feedService = FeedService();

  @override
  void initState() {
    super.initState();
    _loadFetchInterval();
    _buildAndStreamFeed();

    _filterController.addListener(() {
      _filterFeed(_filterController.text);
    });
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
          fetchIntervalInHours,
        );
      }

      if (mounted) {
        final List<PublicationCard> cachedFeed =
            await _feedService.getCachedFeed(context);

        setState(() {
          _allFeed = List.from(cachedFeed);
          _filteredFeed = List.from(_allFeed);
          _sortFeed();
        });

        _feedStreamController.add(_filteredFeed);
      }
    } catch (e) {
      if (mounted) {
        _feedStreamController.addError(e);
      }
    }
  }

  void _sortFeed() {
    setState(() {
      _filteredFeed.sort((a, b) {
        switch (sortBy) {
          case 0: // Sort by published date
            return a.publishedDate!.compareTo(b.publishedDate!);

          case 1: // Sort by title
            if (a.title.isEmpty && b.title.isEmpty) return 0;
            if (a.title.isEmpty) return 1;
            if (b.title.isEmpty) return -1;
            return a.title.compareTo(b.title);

          case 2: // Sort by journal title
            if (a.journalTitle.isEmpty && b.journalTitle.isEmpty) return 0;
            if (a.journalTitle.isEmpty) return 1;
            if (b.journalTitle.isEmpty) return -1;
            return a.journalTitle.compareTo(b.journalTitle);

          case 3: // Sort by first author's family name
            String aFamily = (a.authors.isNotEmpty ? a.authors[0].family : '');
            String bFamily = (b.authors.isNotEmpty ? b.authors[0].family : '');
            if (aFamily.isEmpty && bFamily.isEmpty) return 0;
            if (aFamily.isEmpty) return 1;
            if (bFamily.isEmpty) return -1;
            return aFamily.compareTo(bFamily);

          default:
            return 0;
        }
      });

      if (sortOrder == 1) {
        _filteredFeed = _filteredFeed.reversed.toList();
      }

      _feedStreamController.add(_filteredFeed);
    });
  }

  // Filters the feed using the filter bar
  void _filterFeed(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFeed = List.from(_allFeed);
      } else {
        _filteredFeed = _allFeed
            .where((publication) =>
                publication.title.toLowerCase().contains(query.toLowerCase()) ||
                publication.journalTitle
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                publication.abstract
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                publication.licenseName
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                publication.authors.any((author) => author.family
                    .toLowerCase()
                    .contains(query.toLowerCase())) ||
                publication.authors.any((author) =>
                    author.given.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
      _sortFeed();
    });
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
            _sortFeed();
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
              _sortFeed();
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
        title: Container(
          height: 50.0,
          child: TextField(
            controller: _filterController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.filter,
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
              suffixIcon: PopupMenuButton<int>(
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
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<List<PublicationCard>>(
        stream: _feedStreamController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      AppLocalizations.of(context)!.buildingfeed,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  if (_currentJournalName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        AppLocalizations.of(context)!
                            .fetchingArticleFromJournal(_currentJournalName),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          } else if (_allFeed.isEmpty) {
            // Show a message when allFeed is empty
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  AppLocalizations.of(context)!.homeFeedEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Show a message when filteredFeed is empty
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  AppLocalizations.of(context)!.filterResultsEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              cacheExtent: 1000.0,
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
    _filterController.dispose();
    super.dispose();
  }
}
