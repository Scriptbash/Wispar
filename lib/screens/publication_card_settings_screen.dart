import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/widgets/publication_card/publication_card.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';

class PublicationCardSettingsScreen extends StatefulWidget {
  const PublicationCardSettingsScreen({super.key});

  // Shared preferences keys
  static const String swipeLeftKey = 'swipeLeftAction';
  static const String swipeRightKey = 'swipeRightAction';
  static const String abstractSettingKey = 'publicationCardAbstractSetting';

  static const String showJournalTitleKey = 'showJournalTitle';
  static const String showPublicationDateKey = 'showPublicationDate';
  static const String showAuthorNamesKey = 'showAuthorNames';
  static const String showLicenseKey = 'showLicense';
  static const String showOptionsMenuKey = 'showOptionsMenu';
  static const String showFavoriteButtonKey = 'showFavoriteButton';

  @override
  State<PublicationCardSettingsScreen> createState() =>
      PublicationCardSettingsScreenState();
}

class PublicationCardSettingsScreenState
    extends State<PublicationCardSettingsScreen> {
  SwipeAction _swipeLeftAction = SwipeAction.hide;
  SwipeAction _swipeRightAction = SwipeAction.favorite;

  bool _showJournalTitle = true;
  bool _showPublicationDate = true;
  bool _showAuthorNames = true;
  bool _showAbstract = true;
  bool _showLicense = true;
  bool _showOptionsMenu = true;
  bool _showFavoriteButton = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Map<SwipeAction, ({String title, IconData icon})> get _actionMap {
    final loc = AppLocalizations.of(context)!;
    return {
      SwipeAction.none: (
        title: loc.none,
        icon: Icons.do_not_disturb_on_outlined
      ),
      SwipeAction.favorite: (
        title: loc.addToFavorites,
        icon: Icons.favorite_border
      ),
      SwipeAction.hide: (
        title: loc.hidePublication,
        icon: Icons.visibility_off_outlined
      ),
      SwipeAction.sendToZotero: (
        title: loc.sendToZotero,
        icon: Icons.book_outlined
      ),
      SwipeAction.share: (title: loc.shareArticle, icon: Icons.share_outlined),
    };
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final leftActionName =
        prefs.getString(PublicationCardSettingsScreen.swipeLeftKey) ??
            SwipeAction.hide.name;
    final rightActionName =
        prefs.getString(PublicationCardSettingsScreen.swipeRightKey) ??
            SwipeAction.favorite.name;

    final int abstractOption =
        prefs.getInt(PublicationCardSettingsScreen.abstractSettingKey) ?? 1;

    _showAbstract = (abstractOption == 1 || abstractOption == 0);
    _showJournalTitle =
        prefs.getBool(PublicationCardSettingsScreen.showJournalTitleKey) ??
            true;
    _showPublicationDate =
        prefs.getBool(PublicationCardSettingsScreen.showPublicationDateKey) ??
            true;
    _showAuthorNames =
        prefs.getBool(PublicationCardSettingsScreen.showAuthorNamesKey) ?? true;
    _showLicense =
        prefs.getBool(PublicationCardSettingsScreen.showLicenseKey) ?? true;
    _showOptionsMenu =
        prefs.getBool(PublicationCardSettingsScreen.showOptionsMenuKey) ?? true;
    _showFavoriteButton =
        prefs.getBool(PublicationCardSettingsScreen.showFavoriteButtonKey) ??
            true;

    setState(() {
      try {
        _swipeLeftAction = SwipeAction.values.byName(leftActionName);
      } catch (_) {
        _swipeLeftAction = SwipeAction.hide;
      }
      try {
        _swipeRightAction = SwipeAction.values.byName(rightActionName);
      } catch (_) {
        _swipeRightAction = SwipeAction.favorite;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveSwipeSetting(String key, SwipeAction action) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, action.name);
  }

  Future<void> _saveAbstractSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final int settingValue = value ? 1 : 2;
    await prefs.setInt(
        PublicationCardSettingsScreen.abstractSettingKey, settingValue);
  }

  Future<void> _saveToggleSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Widget _buildDropdown(String title, SwipeAction currentAction,
      ValueSetter<SwipeAction?> onChanged) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<SwipeAction>(
        value: currentAction,
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        items: _actionMap.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Row(
              children: [
                Icon(entry.value.icon, size: 20),
                const SizedBox(width: 8),
                Text(entry.value.title),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.publicationCardSettings),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                    padding: const EdgeInsets.only(
                        top: 16.0, left: 16, right: 16, bottom: 8),
                    child: Text(loc.gestures,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium!)),
                _buildDropdown(
                  loc.swipeLeftAction,
                  _swipeLeftAction,
                  (newAction) {
                    setState(() {
                      _swipeLeftAction = newAction!;
                    });
                    _saveSwipeSetting(
                        PublicationCardSettingsScreen.swipeLeftKey, newAction!);
                  },
                ),
                _buildDropdown(
                  loc.swipeRightAction,
                  _swipeRightAction,
                  (newAction) {
                    setState(() {
                      _swipeRightAction = newAction!;
                    });
                    _saveSwipeSetting(
                        PublicationCardSettingsScreen.swipeRightKey,
                        newAction!);
                  },
                ),
                Divider(),
                Padding(
                    padding: const EdgeInsets.only(
                        top: 16.0, left: 16, right: 16, bottom: 8),
                    child: Text(loc.infoDisplayOnCards,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium!)),
                _buildToggleTile(
                  title: loc.journaltitle,
                  subtitle: null,
                  icon: Icons.article_outlined,
                  value: _showJournalTitle,
                  onChanged: (value) {
                    setState(() {
                      _showJournalTitle = value;
                    });
                    _saveToggleSetting(
                        PublicationCardSettingsScreen.showJournalTitleKey,
                        value);
                  },
                ),
                _buildToggleTile(
                  title: loc.optionsMenu,
                  subtitle: null,
                  icon: Icons.more_vert_outlined,
                  value: _showOptionsMenu,
                  onChanged: (value) {
                    setState(() {
                      _showOptionsMenu = value;
                    });
                    _saveToggleSetting(
                        PublicationCardSettingsScreen.showOptionsMenuKey,
                        value);
                  },
                ),
                _buildToggleTile(
                  title: loc.publicationDate,
                  subtitle: null,
                  icon: Icons.calendar_month_outlined,
                  value: _showPublicationDate,
                  onChanged: (value) {
                    setState(() {
                      _showPublicationDate = value;
                    });
                    _saveToggleSetting(
                        PublicationCardSettingsScreen.showPublicationDateKey,
                        value);
                  },
                ),
                _buildToggleTile(
                  title: loc.authors,
                  subtitle: null,
                  icon: Icons.people_outlined,
                  value: _showAuthorNames,
                  onChanged: (value) {
                    setState(() {
                      _showAuthorNames = value;
                    });
                    _saveToggleSetting(
                        PublicationCardSettingsScreen.showAuthorNamesKey,
                        value);
                  },
                ),
                _buildToggleTile(
                  title: loc.abstract,
                  subtitle: null,
                  icon: Icons.description_outlined,
                  value: _showAbstract,
                  onChanged: (value) {
                    setState(() {
                      _showAbstract = value;
                    });
                    _saveAbstractSetting(value);
                  },
                ),
                _buildToggleTile(
                  title: loc.licenseInfo,
                  subtitle: null,
                  icon: Icons.gavel_outlined,
                  value: _showLicense,
                  onChanged: (value) {
                    setState(() {
                      _showLicense = value;
                    });
                    _saveToggleSetting(
                        PublicationCardSettingsScreen.showLicenseKey, value);
                  },
                ),
                _buildToggleTile(
                  title: loc.favoriteButton,
                  subtitle: null,
                  icon: Icons.favorite_border_outlined,
                  value: _showFavoriteButton,
                  onChanged: (value) {
                    setState(() {
                      _showFavoriteButton = value;
                    });
                    _saveToggleSetting(
                        PublicationCardSettingsScreen.showFavoriteButtonKey,
                        value);
                  },
                ),
              ],
            ),
    );
  }
}
