import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ArticleSearchForm extends StatefulWidget {
  @override
  _ArticleSearchFormState createState() => _ArticleSearchFormState();
}

class _ArticleSearchFormState extends State<ArticleSearchForm> {
  bool saveQuery = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Search Articles"),
        TextField(
          decoration: InputDecoration(
            labelText: 'Article Title',
            border: OutlineInputBorder(),
          ),
        ),
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
        Center(
          child: ElevatedButton(
            onPressed: () {
              print("Search for Articles");
            },
            child: Text('Search'),
          ),
        ),
      ],
    );
  }
}
