import 'package:flutter/material.dart';
import 'settings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text('Home'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                _openSettingsScreen(context);
              },
            ),
          ],
        ),
        body: const Center(
          child: Text('This will be the main feed!'),
        ));
  }
}

_openSettingsScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return SettingsScreen();
      },
    ),
  );
}
