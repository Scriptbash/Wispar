import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import '../widgets/article_search_form.dart';
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(AppLocalizations.of(context)!.search),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*Text(
              AppLocalizations.of(context)!.category,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),*/
            LayoutBuilder(
              builder: (context, constraints) {
                return ToggleButtons(
                  borderRadius: BorderRadius.circular(8.0),
                  isSelected: [
                    selectedSearchType == 1,
                    selectedSearchType == 2,
                  ],
                  onPressed: (int index) {
                    setState(() {
                      selectedSearchType = index == 0 ? 1 : 2;
                    });
                  },
                  children: [
                    Container(
                      width: constraints.maxWidth / 2 - 1.5,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        AppLocalizations.of(context)!.articles,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      width: constraints.maxWidth / 2 - 1.5,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        AppLocalizations.of(context)!.journals,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 8),
            Divider(thickness: 1, color: Colors.grey[300]),
            SizedBox(height: 8),
            Expanded(
                child:
                    _getSearchForm()), // Show form based on selected category
          ],
        ),
      ),
    );
  }

  // Returns the form based on the selected search type
  Widget _getSearchForm() {
    switch (selectedSearchType) {
      case 1:
        return ArticleSearchScreen();
      case 2:
        return JournalSearchForm();
      default:
        return ArticleSearchScreen();
    }
  }
}
