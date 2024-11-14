import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class JournalSearchForm extends StatefulWidget {
  @override
  _JournalSearchFormState createState() => _JournalSearchFormState();
}

class _JournalSearchFormState extends State<JournalSearchForm> {
  bool saveQuery = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Search Journals"),
        TextField(
          decoration: InputDecoration(
            labelText: 'Journal Title',
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
              print("Search for Journals");
            },
            child: Text('Search'),
          ),
        ),
      ],
    );
  }
}
