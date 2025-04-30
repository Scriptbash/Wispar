import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated_l10n/app_localizations.dart';
import './institutions_screen.dart';
import './zotero_settings_screen.dart';

class IntroScreen extends StatefulWidget {
  final VoidCallback onDone;

  const IntroScreen({Key? key, required this.onDone}) : super(key: key);

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  String institutionName = 'No institution';

  @override
  void initState() {
    super.initState();
    _loadInstitution();
  }

  Future<void> _loadInstitution() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedInstitutionName = prefs.getString('institution_name');
    setState(() {
      institutionName =
          (savedInstitutionName == null || savedInstitutionName == "None")
              ? AppLocalizations.of(context)!.noinstitution
              : savedInstitutionName;
    });
  }

  Future<void> saveInstitutionPreference(String name, String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('institution_name', name);
    await prefs.setString('institution_url', url);

    _loadInstitution();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: IntroductionScreen(
      pages: [
        PageViewModel(
          titleWidget: const SizedBox.shrink(),
          bodyWidget: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'assets/icon/icon.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.welcomeWispar,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.appDescription,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          decoration: const PageDecoration(
            contentMargin: EdgeInsets.zero,
            imagePadding: EdgeInsets.zero,
            bodyFlex: 1,
          ),
        ),
        PageViewModel(
          titleWidget: const SizedBox.shrink(),
          bodyWidget: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.school,
                    size: 100, color: Colors.deepPurpleAccent),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.setupInstitutionalAccess,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.setupInstitutionalAccessLong,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () async {
                      final Map<String, dynamic>? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InstitutionScreen(),
                        ),
                      );

                      if (result != null &&
                          result.containsKey('name') &&
                          result.containsKey('url')) {
                        String institutionName = result['name'] as String;
                        String institutionUrl = result['url'] as String;

                        await saveInstitutionPreference(
                            institutionName, institutionUrl);

                        setState(() {
                          this.institutionName = institutionName;
                        });
                      }
                    },
                    child: Text(
                        AppLocalizations.of(context)!.setupSelectInstitution),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${AppLocalizations.of(context)!.setupSelectedInstitution} $institutionName',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          decoration: const PageDecoration(
            contentMargin: EdgeInsets.zero,
            imagePadding: EdgeInsets.zero,
            bodyFlex: 1,
          ),
        ),
        PageViewModel(
          titleWidget: const SizedBox.shrink(),
          bodyWidget: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Icon(Icons.book, size: 100, color: Colors.deepPurpleAccent),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.setupLinkZotero,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.setupZoteroLong,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ZoteroSettings(),
                        ),
                      );
                    },
                    child:
                        Text(AppLocalizations.of(context)!.setupLinkMyZotero),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          decoration: const PageDecoration(
            contentMargin: EdgeInsets.zero,
            imagePadding: EdgeInsets.zero,
            bodyFlex: 1,
          ),
        ),
        PageViewModel(
          titleWidget: const SizedBox.shrink(),
          bodyWidget: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Icon(Icons.settings, size: 100, color: Colors.deepPurpleAccent),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.setupOtherSettings,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.setupOtherSettingsLong,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          decoration: const PageDecoration(
            contentMargin: EdgeInsets.zero,
            imagePadding: EdgeInsets.zero,
            bodyFlex: 1,
          ),
        ),
        PageViewModel(
          titleWidget: const SizedBox.shrink(),
          bodyWidget: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Icon(Icons.check_circle,
                    size: 100, color: Colors.deepPurpleAccent),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.setupAlmostSet,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.setupAlmostSetLong,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          decoration: const PageDecoration(
            contentMargin: EdgeInsets.zero,
            imagePadding: EdgeInsets.zero,
            bodyFlex: 1,
          ),
        ),
      ],
      onDone: widget.onDone,
      showSkipButton: true,
      skip: Text(AppLocalizations.of(context)!.skip,
          style: TextStyle(color: Colors.grey)),
      next: Icon(Icons.arrow_forward,
          color: Theme.of(context).colorScheme.primary),
      done: Text(
        AppLocalizations.of(context)!.getStarted,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary),
      ),
      dotsDecorator: DotsDecorator(
        activeColor: Theme.of(context).colorScheme.primary,
        size: Size(8.0, 8.0),
        activeSize: Size(16.0, 8.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    ));
  }
}
