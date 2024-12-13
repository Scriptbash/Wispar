import 'package:flutter/material.dart';

class QuerySearchForm extends StatefulWidget {
  @override
  _QuerySearchFormState createState() => _QuerySearchFormState();
}

class _QuerySearchFormState extends State<QuerySearchForm> {
  bool isAdvancedSearchVisible = false;
  int selectedSortBy = 0;
  int selectedSortOrder = 0;

  // List of sort by options
  final List<DropdownMenuItem<int>> sortbyItems = [
    DropdownMenuItem(
      value: 0,
      child: Text(
        '-',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 1,
      child: Text(
        'created',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 2,
      child: Text(
        'deposited',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 3,
      child: Text(
        'indexed',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 4,
      child: Text(
        'is-referenced-by-count',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 5,
      child: Text(
        'issued',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 6,
      child: Text(
        'published',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 7,
      child: Text(
        'published-online',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 8,
      child: Text(
        'published-print',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 9,
      child: Text(
        'references-count',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 10,
      child: Text(
        'relevance',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 11,
      child: Text(
        'score',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 12,
      child: Text(
        'updated',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
  ];

  // List of search order by items
  final List<DropdownMenuItem<int>> sortorderItems = [
    DropdownMenuItem(
      value: 0,
      child: Text(
        '-',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 1,
      child: Text(
        'Ascending',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
    DropdownMenuItem(
      value: 2,
      child: Text(
        'Descending',
        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Article Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Author's first name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Author's last name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Publisher',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Sort by',
                    ),
                    value: selectedSortBy,
                    isExpanded: true,
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedSortBy = newValue ?? 1;
                      });
                    },
                    items: sortbyItems,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Sort order',
                    ),
                    value: selectedSortOrder,
                    isExpanded: true,
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedSortOrder = newValue ?? 1;
                      });
                    },
                    items: sortorderItems,
                  ),
                ),
              ],
            ),

            // Collapsible section that shows more search options
            ExpansionTile(
              title: Text('More options'),
              leading: Icon(
                isAdvancedSearchVisible ? Icons.expand_less : Icons.expand_more,
              ),
              trailing: SizedBox(),
              onExpansionChanged: (bool expanded) {
                setState(() {
                  isAdvancedSearchVisible = expanded;
                });
              },
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Affiliation',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Bibliographic",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Degree",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: "Editor first name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: "Editor last name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Event acronym",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Event location",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Event name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Event sponsor",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Event theme",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Funder name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Publisher location",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Standards body acronym",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Standards body name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
