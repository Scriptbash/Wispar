import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../screens/journals_search_results_screen.dart';
import '../services/crossref_api.dart';
import '../models/crossref_journals_models.dart' as Journals;

class JournalSearchForm extends StatefulWidget {
  @override
  _JournalSearchFormState createState() => _JournalSearchFormState();
}

class _JournalSearchFormState extends State<JournalSearchForm> {
  bool saveQuery = false;
  String? selectedSearchlType = 'name';
  late Journals.Item selectedJournal;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (selectedSearchlType == 'issn') {
        String text = _searchController.text;

        // Limit input to 9 characters
        /* if (text.length > 9) {
          _searchController.value = TextEditingValue(
            text: text.substring(0, 9),
            selection: TextSelection.collapsed(offset: 9),
          );
          return;
        }*/

        // Automatically add a dash after the first 4 digits
        /*if (text.length == 4 && !text.contains('-')) {
          _searchController.value = TextEditingValue(
            text: '${text}-',
            selection: TextSelection.collapsed(offset: text.length + 1),
          );
        }*/
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search by',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'name',
                  groupValue: selectedSearchlType,
                  onChanged: (String? value) {
                    setState(() {
                      selectedSearchlType = value;
                      _searchController.clear();
                    });
                  },
                ),
                Text('Journal name'),
                Radio<String>(
                  value: 'issn',
                  groupValue: selectedSearchlType,
                  onChanged: (String? value) {
                    setState(() {
                      selectedSearchlType = value;
                      _searchController.clear();
                    });
                  },
                ),
                Text('ISSN'),
              ],
            ),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText:
                    selectedSearchlType == 'name' ? 'Journal name' : 'ISSN',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          String query = _searchController.text.trim();
          if (query.isNotEmpty) {
            _handleSearch(query);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please enter a search query')),
            );
          }
        },
        child: Icon(Icons.search),
        shape: CircleBorder(),
      ),
    );
  }

  void _handleSearch(String query) async {
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

      CrossRefApi.resetJournalCursor();

      ListAndMore<Journals.Item> searchResults;
      if (selectedSearchlType == 'name') {
        searchResults = await CrossRefApi.queryJournalsByName(query);
      } else if (selectedSearchlType == 'issn') {
        searchResults = await CrossRefApi.queryJournalsByISSN(query);
        print('Search Results: ${searchResults}');
      } else {
        throw Exception('Invalid search type selected');
      }

      Navigator.pop(context);

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
}
