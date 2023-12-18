import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'theme_provider.dart';
import 'screens/home.dart';
import 'screens/favorites.dart';
import 'screens/library.dart';
import 'screens/downloads.dart';

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

  const Wispar({super.key});

  @override
  _WisparState createState() => _WisparState();

  static _WisparState of(BuildContext context) =>
      context.findAncestorStateOfType<_WisparState>()!;
}

class _WisparState extends State<Wispar> {
  //ThemeMode _themeMode = ThemeMode.system;

  var _currentIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const LibraryScreen(),
    const FavoritesScreen(),
    const DownloadsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Wispar.title,
      theme: ThemeData(
        //primarySwatch: Colors.orange,
        colorSchemeSeed: Colors.orange,
        brightness: Brightness.light,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.orange,
        primaryColorDark: Colors.black,
        brightness: Brightness.dark,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      //themeMode: ThemeMode.system,
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      home: Scaffold(
        body: Center(
          child: _pages.elementAt(_currentIndex),
        ),
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.home_outlined),
              title: const Text("Home"),
              selectedColor: Colors.orange,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.library_books_outlined),
              title: const Text("Journals"),
              selectedColor: Colors.orange,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.favorite_border),
              title: const Text("Favorites"),
              selectedColor: Colors.orange,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.download_outlined),
              title: const Text("Downloads"),
              selectedColor: Colors.orange,
            ),
          ],
        ),
      ),
    ); // Closing the MaterialApp widget
  }
}
