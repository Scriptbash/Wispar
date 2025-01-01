import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/crossref_api.dart';
import '../services/string_format_helper.dart';
import '../screens/article_search_results_screen.dart';

class SearchQueryCard extends StatelessWidget {
  final String queryName;
  final String queryParams;
  final String dateSaved;
  final VoidCallback? onDelete;

  const SearchQueryCard({
    Key? key,
    required this.queryName,
    required this.queryParams,
    required this.dateSaved,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime? parsedDate = DateTime.tryParse(dateSaved);
    String formattedDate = formatDate(parsedDate);
    return GestureDetector(
      onTap: () async {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(child: CircularProgressIndicator());
          },
        );
        // Convert the params string to the needed mapstring
        Map<String, dynamic> queryMap = Uri.splitQueryString(queryParams);
        var response = await CrossRefApi.getWorksByQuery(queryMap);

        Navigator.pop(context);
        // Navigate to the search results screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleSearchResultsScreen(
              initialSearchResults: response.list,
              initialHasMore: response.hasMore,
              queryParams: queryMap,
            ),
          ),
        );
      },
      onLongPress: () {
        // Copy the API request to clipboard
        String request = 'https://api.crossref.org/works?$queryParams&rows=50';
        Clipboard.setData(ClipboardData(text: request));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API request copied to clipboard')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    queryName,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                queryParams,
                style: const TextStyle(fontSize: 14.0),
              ),
              const SizedBox(height: 8.0),
              Text(
                "Saved on: $formattedDate",
                style: const TextStyle(fontSize: 12.0, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
