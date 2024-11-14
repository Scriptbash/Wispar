import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/article_search_form.dart';
import '../widgets/author_search_form.dart';
import '../widgets/journal_search_form.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int selectedSearchType = 1; // Default to article type

  // List of search category items
  final List<DropdownMenuItem<int>> dropdownItems = [
    DropdownMenuItem(
      value: 1,
      child: Text(
        'Articles',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 2,
      child: Text(
        'Authors',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 3,
      child: Text(
        'Journals',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(AppLocalizations.of(context)!.search),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Category",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<int>(
              value: selectedSearchType,
              isExpanded: true,
              onChanged: (int? newValue) {
                setState(() {
                  selectedSearchType = newValue ?? 1;
                });
              },
              items: dropdownItems,
            ),
            SizedBox(height: 20),

            // Show form based on selected category
            Expanded(
              child: _getSearchForm(),
            ),
          ],
        ),
      ),
    );
  }

  // Returns the form based on the selected search type
  Widget _getSearchForm() {
    switch (selectedSearchType) {
      case 1:
        return ArticleSearchForm();
      case 2:
        return AuthorSearchForm();
      case 3:
        return JournalSearchForm();
      default:
        return ArticleSearchForm();
    }
  }
}
