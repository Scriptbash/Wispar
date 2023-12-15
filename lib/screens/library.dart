import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text('Journals'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Following"),
              Tab(text: "Not following "),
            ],
          ),
        ),
        body: TabBarView(
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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Filter journals',
            prefixIcon: Icon(Icons.filter_alt),
          ),
        ),
        Text("Journals will be listed here!"),
      ],
    );
  }
}
