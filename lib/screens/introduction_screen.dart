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
    return IntroductionScreen(
      pages: [
        PageViewModel(
            title: AppLocalizations.of(context)!.welcomeWispar,
            body: AppLocalizations.of(context)!.appDescription,
            image: Center(
                child: Image.asset(
              'assets/icon/icon.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            )),
            decoration: const PageDecoration(
              titleTextStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent),
              bodyTextStyle: TextStyle(fontSize: 16),
              imagePadding: EdgeInsets.only(bottom: 20),
            ),
            footer: Padding(
              padding: const EdgeInsets.only(bottom: 30),
            )),
        PageViewModel(
          title: AppLocalizations.of(context)!.setupInstitutionalAccess,
          body: AppLocalizations.of(context)!.setupInstitutionalAccessLong,
          image: Center(
              child: Icon(Icons.school,
                  size: 100, color: Colors.deepPurpleAccent)),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurpleAccent),
            bodyTextStyle: TextStyle(fontSize: 16),
            imagePadding: EdgeInsets.only(bottom: 20),
          ),
          footer: Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                SizedBox(height: 10),
                Text(
                  '${AppLocalizations.of(context)!.setupSelectedInstitution} $institutionName',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        PageViewModel(
          title: AppLocalizations.of(context)!.setupLinkZotero,
          body: AppLocalizations.of(context)!.setupZoteroLong,
          image: Center(
              child:
                  Icon(Icons.book, size: 100, color: Colors.deepPurpleAccent)),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurpleAccent),
            bodyTextStyle: TextStyle(fontSize: 16),
          ),
          footer: Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: SizedBox(
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
                child: Text(AppLocalizations.of(context)!.setupLinkMyZotero),
              ),
            ),
          ),
        ),
        PageViewModel(
            title: AppLocalizations.of(context)!.setupOtherSettings,
            body: AppLocalizations.of(context)!.setupOtherSettingsLong,
            image: Center(
                child: Icon(Icons.settings,
                    size: 100, color: Colors.deepPurpleAccent)),
            decoration: const PageDecoration(
              titleTextStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent),
              bodyTextStyle: TextStyle(fontSize: 16),
            ),
            footer: Padding(
              padding: const EdgeInsets.only(bottom: 30),
            )),
        PageViewModel(
            title: AppLocalizations.of(context)!.setupAlmostSet,
            body: AppLocalizations.of(context)!.setupAlmostSetLong,
            image: Center(
                child: Icon(Icons.check_circle,
                    size: 100, color: Colors.deepPurpleAccent)),
            decoration: const PageDecoration(
              titleTextStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent),
              bodyTextStyle: TextStyle(fontSize: 16),
            ),
            footer: Padding(
              padding: const EdgeInsets.only(bottom: 30),
            )),
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
    );
  }
}
