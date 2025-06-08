import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../generated_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';
import 'locale_provider.dart';
import 'screens/introduction_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/library_screen.dart';
import 'screens/downloads_screen.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import './services/background_service.dart';
import './services/logs_helper.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LogsService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const Wispar(),
    ),
  );
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  await initBackgroundFetch();
}

class Wispar extends StatefulWidget {
  static const title = 'Wispar';

  const Wispar({Key? key}) : super(key: key);

  @override
  _WisparState createState() => _WisparState();
}

class _WisparState extends State<Wispar> {
  bool _hasSeenIntro = false;

  @override
  void initState() {
    super.initState();
    _checkIntroPreference();
  }

  // Load the intro preference
  Future<void> _checkIntroPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner:
          false, // remove debug watermark for screenshots
      title: Wispar.title,
      locale: localeProvider.locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        LocaleNamesLocalizationsDelegate()
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('fr'), // French
        Locale('es'), // Spanish
        Locale('nb'), // Norwegian
        Locale('ta'), // Tamil
        Locale('nl'), // Dutch
        Locale('fa'), // Persian
        Locale('tr'), // Turkish
        Locale('ru'), // Russian
        Locale('ja'), // Japanese
        Locale('id'), // Indonesian
        Locale('pt'), // Portuguese
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
        ), // simplified Chinese
      ],
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      home: Builder(
        builder: (context) {
          return _hasSeenIntro
              ? const HomeScreenNavigator()
              : IntroScreen(
                  onDone: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setBool('hasSeenIntro', true);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            const HomeScreenNavigator(skipToSearch: true),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}

class HomeScreenNavigator extends StatefulWidget {
  final bool skipToSearch;
  const HomeScreenNavigator({Key? key, this.skipToSearch = false})
      : super(key: key);

  @override
  _HomeScreenNavigatorState createState() => _HomeScreenNavigatorState();
}

class _HomeScreenNavigatorState extends State<HomeScreenNavigator> {
  var _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializePageIndex();
  }

  Future<void> _initializePageIndex() async {
    if (widget.skipToSearch) {
      // If skipToSearch is true, default to the Search screen
      setState(() {
        _currentIndex = 1;
      });
    } else {
      // If intro has been seen, default to the Home screen
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  final List<Widget> _pages = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
    const FavoritesScreen(),
    const DownloadsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          /*boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: const Color.fromARGB(43, 0, 0, 0),
            )
          ],*/
        ),
        child: SafeArea(
          child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6),
              child: GNav(
                rippleColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                haptic: true,
                hoverColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                gap: 4,
                activeColor: Theme.of(context).colorScheme.primary,
                iconSize: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                color: Theme.of(context).colorScheme.primary,
                selectedIndex: _currentIndex,
                onTabChange: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                tabs: [
                  GButton(
                    icon: Icons.home_outlined,
                    text: AppLocalizations.of(context)!.home,
                  ),
                  GButton(
                    icon: Icons.search_outlined,
                    text: AppLocalizations.of(context)!.search,
                  ),
                  GButton(
                    icon: Icons.my_library_books_outlined,
                    text: AppLocalizations.of(context)!.library,
                  ),
                  GButton(
                    icon: Icons.favorite_border,
                    text: AppLocalizations.of(context)!.favorites,
                  ),
                  GButton(
                    icon: Icons.download_outlined,
                    text: AppLocalizations.of(context)!.downloads,
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
