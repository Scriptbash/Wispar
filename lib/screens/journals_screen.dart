import 'package:flutter/material.dart';
import '../services/crossref_api.dart';
import '../models/crossref_works_models.dart';
import 'package:wispar/models/crossref_journals_models.dart' as Journals;

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text('Journals'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Following"),
              Tab(text: "Search"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Text("Subscribe to journals to populate this view"),
            Column(
              children: <Widget>[
                SearchTab(),
                // Text("Search over here!")
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Search journals',
            prefixIcon: Icon(Icons.search_outlined),
          ),
          onFieldSubmitted: (String query) {
            // Call the fetchData method when the user submits the search
            fetchData();
          },
        ),
        const Text("Journals will be listed here!"),
      ],
    );
  }
}

Future<void> fetchData() async {
  try {
    List<Journals.Item> items = await CrossRefApi.queryJournals("hydrology");
    // Extract titles from the returned items
    List<String> journalTitles = items.map((item) => item.title).toList();
    print(journalTitles);
  } catch (e, stackTrace) {
    //print('Error coming here: $e, $stackTrace');
  }
}
