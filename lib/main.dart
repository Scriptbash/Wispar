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
      child: SciFeed(),
    ),
  );
}

class SciFeed extends StatefulWidget {
  static final title = 'SciFeed';

  @override
  _SciFeedState createState() => _SciFeedState();

  static _SciFeedState of(BuildContext context) =>
      context.findAncestorStateOfType<_SciFeedState>()!;
}

class _SciFeedState extends State<SciFeed> {
  //ThemeMode _themeMode = ThemeMode.system;

  var _currentIndex = 0;
  final List<Widget> _pages = [
    HomeScreen(),
    FavoritesScreen(),
    LibraryScreen(),
    DownloadsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: SciFeed.title,
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
              icon: Icon(Icons.home),
              title: Text("Home"),
              selectedColor: Colors.orange,
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.favorite_border),
              title: Text("Favorites"),
              selectedColor: Colors.orange,
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.library_books_outlined),
              title: Text("Journals"),
              selectedColor: Colors.orange,
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.download_outlined),
              title: Text("Downloads"),
              selectedColor: Colors.orange,
            ),
          ],
        ),
      ),
    ); // Closing the MaterialApp widget
  }
}