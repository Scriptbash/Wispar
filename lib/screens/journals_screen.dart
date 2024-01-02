import 'package:flutter/material.dart';
import '../services/crossref_api.dart';
import '../models/crossref_works_models.dart';
import './journals_search_results_screen.dart';
import 'package:wispar/models/crossref_journals_models.dart' as Journals;

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: isSearching ? null : Text('Journals'),
        actions: [
          if (isSearching)
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                  ),
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (query) {
                    // Handle search query
                    handleSearch(query);
                  },
                ),
              ),
            ),
          GestureDetector(
            onTap: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                }
              });
            },
            child: Icon(isSearching ? Icons.close : Icons.search),
          ),
        ],
      ),
      body: Center(child: Text('Main Content')),
    );
  }

  void handleSearch(String query) async {
    try {
      List<Journals.Item> searchResults =
          await CrossRefApi.queryJournals(query);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SearchResultsScreen(searchResults: searchResults),
        ),
      );

      setState(() {
        isSearching = false;
      });
    } catch (e, stackTrace) {
      print('Error: $e, $stackTrace');
    }
  }

  Future<void> fetchData(String query) async {
    try {
      List<Journals.Item> items = await CrossRefApi.queryJournals(query);
      // Extract titles from the returned items
      List<String> journalTitles = items.map((item) => item.title).toList();
      print(journalTitles);
    } catch (e, stackTrace) {
      print('Error fetching data: $e, $stackTrace');
    }
  }
}
