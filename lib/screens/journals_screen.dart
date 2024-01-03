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
  late Journal selectedJournal;

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
      // Reset the cursor to "*" only for a new search
      if (query != CrossRefApi.getCurrentQuery()) {
        CrossRefApi.resetCursor();
      }

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
    }
  }

  Future<void> _unfollowJournal(BuildContext context, Journal journal) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.removeJournal(journal.issn);

    // Refresh the UI after unfollowing the journal
    setState(() {});
  }
}

class JournalCard extends StatelessWidget {
  final Journal journal;
  final Function(BuildContext, Journal) unfollowCallback;

  const JournalCard({required this.journal, required this.unfollowCallback});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                journal.title,
                style: TextStyle(
                  //fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                unfollowCallback(context, journal);
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Unfollow',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Publisher: ${journal.publisher}'),
            Text('ISSN: ${journal.issn}'),
            // Text('Subjects: ${journal.subjects}')
          ],
        ),
      ),
    );
  }
}
