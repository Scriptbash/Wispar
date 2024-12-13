import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'article_doi_search_form.dart';
import 'article_query_search_form.dart';

class ArticleSearchForm extends StatefulWidget {
  @override
  _ArticleSearchFormState createState() => _ArticleSearchFormState();
}

class _ArticleSearchFormState extends State<ArticleSearchForm> {
  bool saveQuery = false;
  String? selectedSearchType = 'query';

  @override
  Widget build(BuildContext context) {
    Widget searchForm =
        selectedSearchType == 'query' ? QuerySearchForm() : DOISearchForm();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Search by"),
            Row(
              children: [
                Radio<String>(
                  value: 'query',
                  groupValue: selectedSearchType,
                  onChanged: (String? value) {
                    setState(() {
                      selectedSearchType = value;
                    });
                  },
                ),
                Text('Query'),
                Radio<String>(
                  value: 'doi',
                  groupValue: selectedSearchType,
                  onChanged: (String? value) {
                    setState(() {
                      selectedSearchType = value;
                    });
                  },
                ),
                Text('DOI'),
              ],
            ),
            SizedBox(height: 16),
            // Display the selected search form here
            searchForm,
            SizedBox(height: 16),
            Text(
              'Save this query',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Switch(
              value: saveQuery,
              onChanged: (bool value) {
                setState(() {
                  saveQuery = value;
                });
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Search for Articles");
        },
        child: Icon(Icons.search),
        shape: CircleBorder(),
      ),
    );
  }
}
