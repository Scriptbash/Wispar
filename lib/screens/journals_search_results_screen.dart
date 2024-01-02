import 'package:flutter/material.dart';
import 'package:wispar/models/crossref_journals_models.dart' as Journals;

class SearchResultsScreen extends StatelessWidget {
  final List<Journals.Item> searchResults;

  const SearchResultsScreen({Key? key, required this.searchResults})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
      ),
      body: ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          Journals.Item item = searchResults[index];

          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Journal title
                  Expanded(
                    child: Text(
                      item.title,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3, // Adjust maxLines as needed
                    ),
                  ),

                  // Follow button
                  ElevatedButton(
                    onPressed: () {
                      // Add logic to handle the follow action
                      print('Follow button pressed for ${item.title}');
                    },
                    child: Text('Follow'),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Publisher: ${item.publisher}'),
                  //Text(
                  //    'Subjects: ${item.subjects.map((subject) => subject.name).join(', ')}'),
                ],
              ),
              onTap: () {
                // Handle tap on a card, you can navigate to a detailed screen if needed
                // For example: Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => JournalDetailsScreen(item: item),
                //   ),
                // );
              },
            ),
          );
        },
      ),
    );
  }
}
