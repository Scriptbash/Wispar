import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/crossref_api.dart';
import '../services/database_helper.dart';
import '../models/crossref_works_models.dart';
import './journals_search_results_screen.dart';
import './journals_details_screen.dart';
import 'package:wispar/models/crossref_journals_models.dart' as Journals;

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  late DatabaseHelper dbHelper;
  late Journal selectedJournal;
  late FocusNode searchFocusNode;
  int sortBy = 0; // Set the sort by option to Journal title by default
  int sortOrder = 0; // Set the sort order to Ascending by default

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    searchFocusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            isSearching
                ? Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.search,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.backspace_outlined),
                          onPressed: () {
                            searchController.clear();
                            searchFocusNode.requestFocus();
                          },
                        ),
                      ),
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (query) {
                        handleSearch(query);
                      },
                    ),
                  )
                : Text(AppLocalizations.of(context)!.journals),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                }
              });
            },
          ),
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert),
            onSelected: (item) => handleMenuButton(context, item),
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 0,
                child: ListTile(
                  leading: Icon(Icons.sort),
                  title: Text(AppLocalizations.of(context)!.sortby),
                ),
              ),
              PopupMenuItem<int>(
                value: 1,
                child: ListTile(
                  leading: Icon(Icons.sort_by_alpha),
                  title: Text(AppLocalizations.of(context)!.sortorder),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildLibraryContent(),
    );
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
      case 1:
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

  Widget _buildLibraryContent() {
    return FutureBuilder<List<Journal>>(
      future: dbHelper.getJournals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.journalnotfollowing1),
                Icon(Icons.search),
                Text(AppLocalizations.of(context)!.journalnotfollowing2),
              ],
            ),
          );
        } else {
          List<Journal> journals = snapshot.data!;
          journals.sort((a, b) {
            switch (sortBy) {
              case 0:
                // Sort by Journal title
                return a.title.compareTo(b.title);
              case 1:
                // Sort by Publisher
                return a.publisher.compareTo(b.publisher);
              case 2:
                // Sort by Following date
                return a.dateFollowed!.compareTo(b.dateFollowed!);
              case 3:
                // Sort by ISSN
                return a.issn.compareTo(b.issn);
              default:
                return 0;
            }
          });

          // Reverse the order if sortOrder is Descending
          if (sortOrder == 1) {
            journals = journals.reversed.toList();
          }

          return ListView.builder(
            itemCount: journals.length,
            itemBuilder: (context, index) {
              final currentJournal = journals[index];
              return Column(
                children: [
                  JournalCard(
                    journal: currentJournal,
                    unfollowCallback: _unfollowJournal,
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }

  void handleSearch(String query) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      CrossRefApi.resetCursor();
      await Future.delayed(Duration(milliseconds: 100));
      Navigator.pop(context);
      ListAndMore<Journals.Item> searchResults =
          await CrossRefApi.queryJournals(query);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            searchResults: searchResults,
            searchQuery: query,
          ),
        ),
      );
    } catch (e) {
      print('Error handling search: $e');
      Navigator.pop(context);
    }
  }

  Future<void> _unfollowJournal(BuildContext context, Journal journal) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.removeJournal(journal.issn);

    // Refresh the UI after unfollowing the journal
    setState(() {});
  }
}

class JournalCard extends StatelessWidget {
  final Journal journal;
  final Function(BuildContext, Journal) unfollowCallback;

  const JournalCard({required this.journal, required this.unfollowCallback});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        onTap: () {
          List<String> subjects = journal.subjects.split(', ');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JournalDetailsScreen(
                title: journal.title,
                publisher: journal.publisher,
                issn: journal.issn,
                subjects: subjects,
              ),
            ),
          );
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                journal.title,
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                // Perform the unfollow action
                unfollowCallback(context, journal);
              },
              child: Text(AppLocalizations.of(context)!.unfollow),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${AppLocalizations.of(context)!.publisher}: ${journal.publisher}'),
            Text('ISSN: ${journal.issn}'),
            Text(
                '${AppLocalizations.of(context)!.followingsince} ${journal.dateFollowed}'),
          ],
        ),
      ),
    );
  }
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
