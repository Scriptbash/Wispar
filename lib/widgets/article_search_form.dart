import 'package:flutter/material.dart';
import './article_crossref_search_form.dart';
import './article_openAlex_search_form.dart';

class ArticleSearchScreen extends StatefulWidget {
  @override
  _ArticleSearchScreenState createState() => _ArticleSearchScreenState();
}

class _ArticleSearchScreenState extends State<ArticleSearchScreen> {
  int selectedProviderIndex = 0; // 0 = OpenAlex, 1 = Crossref

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ToggleButtons(
          borderRadius: BorderRadius.circular(8.0),
          isSelected: [selectedProviderIndex == 0, selectedProviderIndex == 1],
          onPressed: (int index) {
            setState(() {
              selectedProviderIndex = index;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text('OpenAlex'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text('Crossref'),
            ),
          ],
        ),
        SizedBox(height: 20),
        Expanded(
          child: selectedProviderIndex == 0
              ? OpenAlexSearchForm()
              : CrossRefSearchForm(),
        ),
      ],
    );
  }
}
