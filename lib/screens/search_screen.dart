import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/article_main_search_form.dart';
import '../widgets/author_search_form.dart';
import '../widgets/journal_search_form.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int selectedSearchType = 1; // Default to article type

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<int>> dropdownItems = [
      DropdownMenuItem(
        value: 1,
        child: Text(
          AppLocalizations.of(context)!.articles,
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
        ),
      ),
      /*DropdownMenuItem(
        value: 2,
        child: Text(
          AppLocalizations.of(context)!.authors,
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
        ),
      ),*/
      DropdownMenuItem(
        value: 3,
        child: Text(
          AppLocalizations.of(context)!.journals,
          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
        ),
      ),
    ];

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
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.category,
              ),
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
