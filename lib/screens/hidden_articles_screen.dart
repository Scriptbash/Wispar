import 'package:flutter/material.dart';
import 'package:wispar/services/database_helper.dart';
import 'package:wispar/widgets/publication_card/publication_card.dart';
import 'package:wispar/screens/publication_card_settings_screen.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HiddenArticlesScreen extends StatefulWidget {
  const HiddenArticlesScreen({super.key});

  @override
  HiddenArticlesScreenState createState() => HiddenArticlesScreenState();
}

class HiddenArticlesScreenState extends State<HiddenArticlesScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<PublicationCard> _hiddenPublications = [];

  SwipeAction _swipeLeftAction = SwipeAction.hide;
  SwipeAction _swipeRightAction = SwipeAction.favorite;

  bool _showJournalTitle = true;
  bool _showPublicationDate = true;
  bool _showAuthorNames = true;
  bool _showLicense = true;
  bool _showOptionsMenu = true;
  bool _showFavoriteButton = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _loadHiddenPublications();
  }

  Future<void> _loadAllData() async {
    await _loadCardPreferences();
    await _loadHiddenPublications();
  }

  Future<void> _loadCardPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final leftActionName =
        prefs.getString('swipeLeftAction') ?? SwipeAction.hide.name;
    final rightActionName =
        prefs.getString('swipeRightAction') ?? SwipeAction.favorite.name;

    SwipeAction newLeftAction = SwipeAction.hide;
    SwipeAction newRightAction = SwipeAction.favorite;

    try {
      newLeftAction = SwipeAction.values.byName(leftActionName);
    } catch (_) {
      newLeftAction = SwipeAction.hide;
    }
    try {
      newRightAction = SwipeAction.values.byName(rightActionName);
    } catch (_) {
      newRightAction = SwipeAction.favorite;
    }

    if (mounted) {
      setState(() {
        _swipeLeftAction = newLeftAction;
        _swipeRightAction = newRightAction;
        _showJournalTitle =
            prefs.getBool(PublicationCardSettingsScreen.showJournalTitleKey) ??
                true;
        _showPublicationDate = prefs.getBool(
                PublicationCardSettingsScreen.showPublicationDateKey) ??
            true;
        _showAuthorNames =
            prefs.getBool(PublicationCardSettingsScreen.showAuthorNamesKey) ??
                true;
        _showLicense =
            prefs.getBool(PublicationCardSettingsScreen.showLicenseKey) ?? true;
        _showOptionsMenu =
            prefs.getBool(PublicationCardSettingsScreen.showOptionsMenuKey) ??
                true;
        _showFavoriteButton = prefs
                .getBool(PublicationCardSettingsScreen.showFavoriteButtonKey) ??
            true;
      });
    }
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
          swipeLeftAction: _swipeLeftAction,
          swipeRightAction: _swipeRightAction,
          showJournalTitle: _showJournalTitle,
          showPublicationDate: _showPublicationDate,
          showAuthorNames: _showAuthorNames,
          showLicense: _showLicense,
          showOptionsMenu: _showOptionsMenu,
          showFavoriteButton: _showFavoriteButton,
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
