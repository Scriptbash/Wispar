import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/crossref_api.dart';
import '../services/database_helper.dart';
import '../widgets/sortbydialog.dart';
import '../widgets/sortorderdialog.dart';
import '../models/journal_entity.dart';
import '../widgets/journal_card.dart';
import './journals_search_results_screen.dart';
import 'package:wispar/models/crossref_journals_models.dart' as Journals;

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  late DatabaseHelper dbHelper;
  late Journals.Item selectedJournal;
  late FocusNode searchFocusNode;
  late final TabController _tabController;

  int sortBy = 0; // Set the sort by option to Journal title by default
  int sortOrder = 0; // Set the sort order to Ascending by default

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    searchFocusNode = FocusNode();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            isSearching
                ? Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.search,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.backspace_outlined),
                          onPressed: () {
                            searchController.clear();
                            searchFocusNode.requestFocus();
                          },
                        ),
                      ),
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (query) {
                        handleSearch(query);
                      },
                    ),
                  )
                : Text(AppLocalizations.of(context)!.library),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                }
              });
            },
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
                  title: Text(AppLocalizations.of(context)!.sortorder),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(
              icon: Icon(Icons.menu_book_rounded),
              text: AppLocalizations.of(context)!.journals,
            ),
            Tab(
              icon: Icon(Icons.person_2_outlined),
              text: AppLocalizations.of(context)!.authors,
            ),
            Tab(
              icon: Icon(Icons.format_quote_rounded),
              text: "Custom queries",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          Center(child: _buildLibraryContent()),
          Center(
            child: Text("Followed authors will show here"),
          ),
          Center(
            child: Text("Followed search queries will show here"),
          ),
        ],
      ),
    );
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
            AppLocalizations.of(context)!.journaltitle,
            AppLocalizations.of(context)!.publisher,
            AppLocalizations.of(context)!.followingdate,
            'ISSN',
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

  Widget _buildLibraryContent() {
    return FutureBuilder<List<Journal>>(
      future: dbHelper.getJournals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.journalnotfollowing1),
                Icon(Icons.search),
                Text(AppLocalizations.of(context)!.journalnotfollowing2),
              ],
            ),
          );
        } else {
          List<Journal> journals = snapshot.data!;
          journals.sort((a, b) {
            switch (sortBy) {
              case 0:
                // Sort by Journal title
                return a.title.compareTo(b.title);
              case 1:
                // Sort by Publisher
                return a.publisher.compareTo(b.publisher);
              case 2:
                // Sort by Following date
                return a.dateFollowed!.compareTo(b.dateFollowed!);
              case 3:
                // Sort by ISSN
                return a.issn.compareTo(b.issn);
              default:
                return 0;
            }
          });

          // Reverse the order if sortOrder is Descending
          if (sortOrder == 1) {
            journals = journals.reversed.toList();
          }

          return ListView.builder(
            itemCount: journals.length,
            itemBuilder: (context, index) {
              final currentJournal = journals[index];
              return Column(
                children: [
                  JournalCard(
                    journal: currentJournal,
                    unfollowCallback: _unfollowJournal,
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }

  void handleSearch(String query) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      CrossRefApi.resetJournalCursor();
      await Future.delayed(Duration(milliseconds: 100));
      Navigator.pop(context);
      ListAndMore<Journals.Item> searchResults =
          await CrossRefApi.queryJournals(query);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            searchResults: searchResults,
            searchQuery: query,
          ),
        ),
      );
    } catch (e) {
      print('Error handling search: $e');
      Navigator.pop(context);
    }
  }

  Future<void> _unfollowJournal(BuildContext context, Journal journal) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.removeJournal(journal.issn);
    // Clear the publication cache to force update the home screen
    //await dbHelper.clearCachedPublications();
    // Refresh the UI after unfollowing the journal
    setState(() {});
  }
}
