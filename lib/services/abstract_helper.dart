import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AbstractSetting { showAll, hideAll, hideMissing }

class AbstractHelper {
  static Future<AbstractSetting> getAbstractSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final int setting = prefs.getInt('publicationCardAbstractSetting') ?? 1;

    switch (setting) {
      case 1:
        return AbstractSetting.hideMissing;
      case 2:
        return AbstractSetting.hideAll;
      case 3:
      default:
        return AbstractSetting.showAll;
    }
  }

  static Future<String> buildAbstract(
      BuildContext context, String abstract) async {
    AbstractSetting setting = await getAbstractSetting();

    switch (setting) {
      case AbstractSetting.hideAll:
        return ''; // Return an empty string if abstracts should be hidden
      case AbstractSetting.hideMissing:
        return abstract.isNotEmpty ? abstract : ''; // Only show if not empty
      case AbstractSetting.showAll:
    }
    return abstract.isNotEmpty
        ? abstract
        : AppLocalizations.of(context)!.abstractunavailable;
  }
}
