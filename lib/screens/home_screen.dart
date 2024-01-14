import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  int sortBy = 0;
  int sortOrder = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text(AppLocalizations.of(context)!.home),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.search),
              //tooltip: 'Settings',
              onPressed: () {
                //_openSettingsScreen(context);
              },
            ),
            PopupMenuButton<int>(
              icon: Icon(Icons.more_vert),
              onSelected: (item) => handleMenuButton(context, item),
              itemBuilder: (context) => [
                PopupMenuItem<int>(
                  value: 0,
                  child: ListTile(
                    leading: Icon(Icons.settings_outlined),
                    title: Text(AppLocalizations.of(context)!.settings),
                  ),
                ),
                PopupMenuItem<int>(
                  value: 1,
                  child: ListTile(
                    leading: Icon(Icons.sort),
                    title: Text(AppLocalizations.of(context)!.sortby),
                  ),
                ),
                PopupMenuItem<int>(
                  value: 2,
                  child: ListTile(
                    leading: Icon(Icons.sort_by_alpha),
                    title: Text(AppLocalizations.of(context)!.sortorder),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: const Center(
          child: Text('This will be the main feed!'),
        ));
  }

  void _handleSortByChanged(int value) {
    setState(() {
      sortBy = value;
    });
  }

  void _handleSortOrderChanged(int value) {
    setState(() {
      sortOrder = value;
    });
  }

  void handleMenuButton(BuildContext context, int item) {
    switch (item) {
      case 0:
        _openSettingsScreen(context);
        break;
      case 1:
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return SortByDialog(
              initialSortBy: sortBy,
              onSortByChanged: _handleSortByChanged,
            );
          },
        );
        break;
      case 2:
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return SortOrderDialog(
              initialSortOrder: sortOrder,
              onSortOrderChanged: _handleSortOrderChanged,
            );
          },
        );

        break;
    }
  }
}

_openSettingsScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return const SettingsScreen();
      },
    ),
  );
}

class SortByDialog extends StatefulWidget {
  final int initialSortBy;
  final ValueChanged<int> onSortByChanged;

  SortByDialog({required this.initialSortBy, required this.onSortByChanged});

  @override
  _SortByDialogState createState() => _SortByDialogState();
}

class _SortByDialogState extends State<SortByDialog> {
  late int selectedSortBy;

  @override
  void initState() {
    super.initState();
    selectedSortBy = widget.initialSortBy;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.sortby),
      content: SingleChildScrollView(
        child: Column(
          children: [
            RadioListTile<int>(
              value: 0,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
              },
              title: Text(AppLocalizations.of(context)!.journaltitle),
            ),
            RadioListTile<int>(
              value: 1,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
              },
              title: Text(AppLocalizations.of(context)!.publisher),
            ),
            RadioListTile<int>(
              value: 2,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
              },
              title: Text(AppLocalizations.of(context)!.followingdate),
            ),
            RadioListTile<int>(
              value: 3,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                setState(() {
                  selectedSortBy = value!;
                  widget.onSortByChanged(selectedSortBy);
                });
              },
              title: Text('ISSN'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('OK'),
        ),
      ],
    );
  }
}

class SortOrderDialog extends StatefulWidget {
  final int initialSortOrder;
  final ValueChanged<int> onSortOrderChanged;

  SortOrderDialog(
      {required this.initialSortOrder, required this.onSortOrderChanged});

  @override
  _SortOrderDialogState createState() => _SortOrderDialogState();
}

class _SortOrderDialogState extends State<SortOrderDialog> {
  late int selectedSortOrder;

  @override
  void initState() {
    super.initState();
    selectedSortOrder = widget.initialSortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.sortorder),
      content: SingleChildScrollView(
        child: Column(
          children: [
            RadioListTile<int>(
              value: 0,
              groupValue: selectedSortOrder,
              onChanged: (int? value) {
                setState(() {
                  selectedSortOrder = value!;
                  widget.onSortOrderChanged(selectedSortOrder);
                });
              },
              title: Text(AppLocalizations.of(context)!.ascending),
            ),
            RadioListTile<int>(
              value: 1,
              groupValue: selectedSortOrder,
              onChanged: (int? value) {
                setState(() {
                  selectedSortOrder = value!;
                  widget.onSortOrderChanged(selectedSortOrder);
                });
              },
              title: Text(AppLocalizations.of(context)!.descending),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('OK'),
        ),
      ],
    );
  }
}
