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
      //mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        TextFormField(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40.0),
            ),
            //labelText: 'Search journals',
            hintText: 'Search journals',
            prefixIcon: Icon(Icons.search_outlined),
          ),
          onFieldSubmitted: (String query) {
            // Call the fetchData method when the user submits the search
            fetchData();
          },
        ),
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
