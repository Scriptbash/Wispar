import 'package:flutter/material.dart';
import '../services/crossref_api.dart';
import '../services/database_helper.dart';
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
  late DatabaseHelper dbHelper;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: isSearching
            ? TextField(
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
              )
            : const Text('Journals'),
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
        ],
      ),
      body: _buildLibraryContent(),
    );
  }

  Widget _buildLibraryContent() {
    return FutureBuilder<List<Journal>>(
      future: dbHelper.getJournals(), // Fetch journals from the database
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
                Text('You are not following any journals. Use the '),
                Icon(Icons.search),
                Text(' icon to find and follow journals.'),
              ],
            ),
          );
        } else {
          List<Journal> journals = snapshot.data!;
          return ListView.builder(
            itemCount: journals.length,
            itemBuilder: (context, index) {
              return JournalCard(journal: journals[index]);
            },
          );
        }
      },
    );
  }

  void handleSearch(String query) async {
    try {
      // Reset the cursor to "*" only for a new search
      if (query != CrossRefApi.getCurrentQuery()) {
        CrossRefApi.resetCursor();
      }
      List<Journals.Item> searchResults =
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

      setState(() {
        isSearching = false;
      });

      // Check if there are more items before updating the cursor
      if (searchResults.isNotEmpty && CrossRefApi.cursor != null) {
        // Access the cursor using the getter
        String? nextCursor = CrossRefApi.cursor;
        // Use nextCursor as needed
      }
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

class JournalCard extends StatelessWidget {
  final Journal journal;

  const JournalCard({required this.journal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(journal.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Publisher: ${journal.publisher}'),
            Text('ISSN: ${journal.issn}'),
            //Text('Subjects: ${journal.subjects}')
          ],
        ),
      ),
    );
  }
}
