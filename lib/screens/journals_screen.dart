import 'package:flutter/material.dart';

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
              Tab(text: "Find more journals"),
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
        ),
        const Text("Journals will be listed here!"),
      ],
    );
  }
}
