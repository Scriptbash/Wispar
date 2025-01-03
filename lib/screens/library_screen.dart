import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/database_helper.dart';
import '../widgets/journals_tab_content.dart';
//import '../widgets/authors_tab_content.dart';
import '../widgets/queries_tab_content.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  bool isSearching = false;
  late DatabaseHelper dbHelper;
  late FocusNode searchFocusNode;
  late final TabController _tabController;

  int journalsSortBy = 0; // Set the sort by option to Journal title by default
  int journalsSortOrder = 0; // Set the sort order to Ascending by default
  int authorsSortBy = 0; // Set the sort by option to Journal title by default
  int authorsSortOrder = 0; // Set the sort order to Ascending by default
  int queriesSortBy = 0; // Set the sort by option to Queriy name by default
  int queriesSortOrder = 0; // Set the sort order to Ascending by default

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    searchFocusNode = FocusNode();
    _tabController = TabController(length: 2, vsync: this);
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
        title: Text(AppLocalizations.of(context)!.library),
        bottom: TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(
              icon: Icon(Icons.menu_book_rounded),
              text: AppLocalizations.of(context)!.journals,
            ),
            /*ab(
              icon: Icon(Icons.person_2_outlined),
              text: AppLocalizations.of(context)!.authors,
            ),*/
            Tab(
              icon: Icon(Icons.format_quote_rounded),
              text: AppLocalizations.of(context)!.queries,
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
          /*AuthorsTabContent(
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
          ),*/
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
}
