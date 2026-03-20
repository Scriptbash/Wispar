import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/theme_provider.dart';
import 'package:wispar/locale_provider.dart';
import 'package:wispar/screens/introduction_screen.dart';
import 'package:wispar/screens/home_screen.dart';
import 'package:wispar/screens/search_screen.dart';
import 'package:wispar/screens/favorites_screen.dart';
import 'package:wispar/screens/library_screen.dart';
import 'package:wispar/screens/downloads_screen.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:wispar/services/background_service.dart';
import 'package:wispar/services/logs_helper.dart';
import 'package:wispar/services/pocketbase_service.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:wispar/services/sync_service.dart';
import 'package:wispar/webview_env.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    final availableVersion = await WebViewEnvironment.getAvailableVersion();
    if (availableVersion == null) {
      return;
    }

    final appDataDir = await getApplicationSupportDirectory();

    webViewEnvironment = await WebViewEnvironment.create(
      settings: WebViewEnvironmentSettings(
        userDataFolder: '${appDataDir.path}\\WisparWebView',
      ),
    );
  }

  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  LogsService();
  await PocketBaseService().init();
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(900, 700),
      minimumSize: Size(400, 600),
      center: true,
      title: "Wispar",
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const Wispar(),
    ),
  );
  if (Platform.isAndroid || Platform.isIOS) {
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
    await initBackgroundFetch();
  }
}

class Wispar extends StatefulWidget {
  static const title = 'Wispar';

  const Wispar({super.key});

  @override
  WisparState createState() => WisparState();
}

class WisparState extends State<Wispar> {
  bool _hasSeenIntro = false;
  final pbService = PocketBaseService();
  final syncManager = SyncManager();

  @override
  void initState() {
    super.initState();
    _checkIntroPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncManager.triggerBackgroundSync();
    });
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
      debugShowCheckedModeBanner: false,
      // remove debug watermark for screenshots
      title: Wispar.title,
      locale: localeProvider.locale,
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
        Locale('ru'), // Russian
        Locale('ja'), // Japanese
        Locale('id'), // Indonesian
        Locale('pt'), // Portuguese
        Locale('de'), // German
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

  const HomeScreenNavigator({super.key, this.skipToSearch = false});

  @override
  HomeScreenNavigatorState createState() => HomeScreenNavigatorState();
}

class HomeScreenNavigatorState extends State<HomeScreenNavigator> {
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
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              labelType: NavigationRailLabelType.selected,
              selectedIconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.primary,
              ),
              unselectedIconTheme:
                  IconThemeData(color: Theme.of(context).colorScheme.primary),
              selectedLabelTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text(AppLocalizations.of(context)!.home),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search),
                  label: Text(AppLocalizations.of(context)!.search),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.my_library_books_outlined),
                  selectedIcon: Icon(Icons.library_books),
                  label: Text(AppLocalizations.of(context)!.library),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: Text(AppLocalizations.of(context)!.favorites),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.download_outlined),
                  selectedIcon: Icon(Icons.download),
                  label: Text(AppLocalizations.of(context)!.downloads),
                ),
              ],
            ),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: GNav(
                    rippleColor:
                        Theme.of(context).colorScheme.primary.withAlpha(25),
                    hoverColor:
                        Theme.of(context).colorScheme.primary.withAlpha(25),
                    gap: 4,
                    activeColor: Theme.of(context).colorScheme.primary,
                    iconSize: 24,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    duration: const Duration(milliseconds: 400),
                    tabBackgroundColor:
                        Theme.of(context).colorScheme.primary.withAlpha(25),
                    color: Theme.of(context).colorScheme.primary,
                    selectedIndex: _currentIndex,
                    onTabChange: (index) {
                      setState(() => _currentIndex = index);
                    },
                    tabs: [
                      GButton(
                        icon: _currentIndex == 0
                            ? Icons.home
                            : Icons.home_outlined,
                        text: AppLocalizations.of(context)!.home,
                      ),
                      GButton(
                        icon: _currentIndex == 1
                            ? Icons.search
                            : Icons.search_outlined,
                        text: AppLocalizations.of(context)!.search,
                      ),
                      GButton(
                        icon: _currentIndex == 2
                            ? Icons.library_books
                            : Icons.my_library_books_outlined,
                        text: AppLocalizations.of(context)!.library,
                      ),
                      GButton(
                        icon: _currentIndex == 3
                            ? Icons.favorite
                            : Icons.favorite_border,
                        text: AppLocalizations.of(context)!.favorites,
                      ),
                      GButton(
                        icon: _currentIndex == 4
                            ? Icons.download
                            : Icons.download_outlined,
                        text: AppLocalizations.of(context)!.downloads,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
