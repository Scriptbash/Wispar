import 'package:flutter/material.dart';

class AuthorSearchForm extends StatefulWidget {
  @override
  _AuthorSearchFormState createState() => _AuthorSearchFormState();
}

class _AuthorSearchFormState extends State<AuthorSearchForm> {
  bool saveQuery = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Search Authors"),
        TextField(
          decoration: InputDecoration(
            labelText: 'Author Name',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        Text('Save this query', style: TextStyle(fontWeight: FontWeight.bold)),
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
              print("Search for Authors");
            },
            child: Text('Search'),
          ),
        ),
      ],
    );
  }
}
