import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';
import 'screens/introduction_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/library_screen.dart';
import 'screens/downloads_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const Wispar(),
    ),
  );
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
    return MaterialApp(
      debugShowCheckedModeBanner:
          false, // remove debug watermark for screenshots
      title: Wispar.title,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
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

  String getLocalizedText(BuildContext context, String key) {
    switch (key) {
      case 'home':
        return AppLocalizations.of(context)!.home;
      case 'search':
        return AppLocalizations.of(context)!.search;
      case 'library':
        return AppLocalizations.of(context)!.library;
      case 'favorites':
        return AppLocalizations.of(context)!.favorites;
      case 'downloads':
        return AppLocalizations.of(context)!.downloads;
      default:
        return key; // Return the key if the translation is not found
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Builder(
        builder: (BuildContext bottomBarContext) => SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.home_outlined),
              title: Text(getLocalizedText(bottomBarContext, 'home')),
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.search_outlined),
              title: Text(getLocalizedText(bottomBarContext, 'search')),
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.my_library_books_outlined),
              title: Text(getLocalizedText(bottomBarContext, 'library')),
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.favorite_border),
              title: Text(getLocalizedText(bottomBarContext, 'favorites')),
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.download_outlined),
              title: Text(getLocalizedText(bottomBarContext, 'downloads')),
              selectedColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
