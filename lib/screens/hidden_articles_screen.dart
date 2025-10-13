import 'package:flutter/material.dart';
import 'package:wispar/services/database_helper.dart';
import 'package:wispar/widgets/publication_card/publication_card.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';

class HiddenArticlesScreen extends StatefulWidget {
  const HiddenArticlesScreen({super.key});

  @override
  HiddenArticlesScreenState createState() => HiddenArticlesScreenState();
}

class HiddenArticlesScreenState extends State<HiddenArticlesScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<PublicationCard> _hiddenPublications = [];

  @override
  void initState() {
    super.initState();
    _loadHiddenPublications();
  }

  Future<void> _loadHiddenPublications() async {
    final hidden = await dbHelper.getHiddenPublications();

    setState(() {
      _hiddenPublications = hidden.map((card) {
        return PublicationCard(
          key: ValueKey(card.doi),
          doi: card.doi,
          title: card.title,
          issn: card.issn,
          abstract: card.abstract,
          journalTitle: card.journalTitle,
          publishedDate: card.publishedDate,
          authors: card.authors,
          url: card.url,
          license: card.license,
          licenseName: card.licenseName,
          showHideBtn: true,
          isHidden: true,
          onHide: () async {
            setState(() {
              _hiddenPublications.removeWhere((c) => c.doi == card.doi);
            });
          },
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.hiddenArticles)),
      body: _hiddenPublications.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.noHiddenArticles))
          : ListView.builder(
              itemCount: _hiddenPublications.length,
              itemBuilder: (context, index) {
                return _hiddenPublications[index];
              },
            ),
    );
  }
}
