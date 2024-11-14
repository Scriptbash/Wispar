import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/crossref_api.dart';
import '../services/database_helper.dart';
import '../widgets/sortbydialog.dart';
import '../widgets/sortorderdialog.dart';
import '../models/journal_entity.dart';
import '../widgets/journal_card.dart';
import '../widgets/journals_tab_content.dart';
import '../widgets/authors_tab_content.dart';
import '../widgets/queries_tab_content.dart';
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

  int journalsSortBy = 0; // Set the sort by option to Journal title by default
  int journalsSortOrder = 0; // Set the sort order to Ascending by default
  int authorsSortBy = 0; // Set the sort by option to Journal title by default
  int authorsSortOrder = 0; // Set the sort order to Ascending by default
  int queriesSortBy = 0; // Set the sort by option to Journal title by default
  int queriesSortOrder = 0; // Set the sort order to Ascending by default

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
          /* PopupMenuButton<int>(
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
          ),*/
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
              text: "Queries",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          JournalsTabContent(
            initialSortBy: journalsSortBy,
            initialSortOrder: journalsSortOrder,
            onSortByChanged: (int value) {
              setState(() {
                journalsSortBy = value;
              });
            },
            onSortOrderChanged: (int value) {
              setState(() {
                journalsSortOrder = value;
              });
            },
          ),
          AuthorsTabContent(
            initialSortBy: authorsSortBy,
            initialSortOrder: authorsSortOrder,
            onSortByChanged: (int value) {
              setState(() {
                authorsSortBy = value;
              });
            },
            onSortOrderChanged: (int value) {
              setState(() {
                authorsSortOrder = value;
              });
            },
          ),
          QueriesTabContent(
            initialSortBy: queriesSortBy,
            initialSortOrder: queriesSortOrder,
            onSortByChanged: (int value) {
              setState(() {
                queriesSortBy = value;
              });
            },
            onSortOrderChanged: (int value) {
              setState(() {
                queriesSortOrder = value;
              });
            },
          ),
        ],
      ),
    );
  }

  /*// Handles the sort by and sort order options
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
    return Column(
      children: [
        // Row with Sort By and Sort Order buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () => handleMenuButton(0), // Sort By
                child: Text(AppLocalizations.of(context)!.sortby),
              ),
              ElevatedButton(
                onPressed: () => handleMenuButton(1), // Sort Order
                child: Text(AppLocalizations.of(context)!.sortorder),
              ),
            ],
          ),
        ),
        // Space between the buttons and the journal list
        Expanded(
          child: FutureBuilder<List<Journal>>(
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
                      return a.title.compareTo(b.title);
                    case 1:
                      return a.publisher.compareTo(b.publisher);
                    case 2:
                      return a.dateFollowed!.compareTo(b.dateFollowed!);
                    case 3:
                      return a.issn.compareTo(b.issn);
                    default:
                      return 0;
                  }
                });

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
          ),
        ),
      ],
    );
  }
*/
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
/*
  Future<void> _unfollowJournal(BuildContext context, Journal journal) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.removeJournal(journal.issn);
    // Clear the publication cache to force update the home screen
    //await dbHelper.clearCachedPublications();
    // Refresh the UI after unfollowing the journal
    setState(() {});
  }*/
}
