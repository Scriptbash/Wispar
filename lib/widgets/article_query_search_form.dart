import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/screens/article_search_results_screen.dart';
import 'package:wispar/services/database_helper.dart';

class QuerySearchForm extends StatefulWidget {
  // The key allows to access the state of the form from outside
  const QuerySearchForm({super.key});

  @override
  QuerySearchFormState createState() => QuerySearchFormState();
}

class QuerySearchFormState extends State<QuerySearchForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime? _createdAfter;
  DateTime? _createdBefore;
  String _dateMode = 'none';
  bool isAdvancedSearchVisible = false;
  bool saveQuery = false;
  int selectedSortBy = 0;
  int selectedSortOrder = 0;

  // Controllers for text fields
  final TextEditingController titleController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController publisherController = TextEditingController();
  final TextEditingController affiliationController = TextEditingController();
  final TextEditingController bibliographicController = TextEditingController();
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController editorFirstNameController =
      TextEditingController();
  final TextEditingController editorLastNameController =
      TextEditingController();
  final TextEditingController eventAcronymController = TextEditingController();
  final TextEditingController eventLocationController = TextEditingController();
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventSponsorController = TextEditingController();
  final TextEditingController eventThemeController = TextEditingController();
  final TextEditingController funderNameController = TextEditingController();
  final TextEditingController publisherLocationController =
      TextEditingController();
  final TextEditingController standardsBodyAcronymController =
      TextEditingController();
  final TextEditingController standardsBodyNameController =
      TextEditingController();

  final TextEditingController queryNameController = TextEditingController();

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
  void dispose() {
    titleController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    publisherController.dispose();
    affiliationController.dispose();
    bibliographicController.dispose();
    degreeController.dispose();
    descriptionController.dispose();
    editorFirstNameController.dispose();
    editorLastNameController.dispose();
    eventAcronymController.dispose();
    eventLocationController.dispose();
    eventNameController.dispose();
    eventSponsorController.dispose();
    eventThemeController.dispose();
    funderNameController.dispose();
    publisherLocationController.dispose();
    standardsBodyAcronymController.dispose();
    standardsBodyNameController.dispose();
    queryNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isAfter) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isAfter) {
          _createdAfter = picked;
        } else {
          _createdBefore = picked;
        }
      });
    }
  }

  void submitForm() async {
    // Gather all input values, ignoring empty fields
    final Map<String, dynamic> queryParams = {};

    final title = titleController.text.trim();
    if (title.isNotEmpty) queryParams['query.title'] = title;

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      final author =
          '$firstName $lastName'.trim(); // Combine first and last name
      queryParams['query.author'] = author;
    }
    final publisher = publisherController.text.trim();
    if (publisher.isNotEmpty) queryParams['query.publisher-name'] = publisher;

    final affiliation = affiliationController.text.trim();
    if (affiliation.isNotEmpty) queryParams['query.affiliation'] = affiliation;

    final bibliographic = bibliographicController.text.trim();
    if (bibliographic.isNotEmpty) {
      queryParams['query.bibliographic'] = bibliographic;
    }

    final degree = degreeController.text.trim();
    if (degree.isNotEmpty) queryParams['query.degree'] = degree;

    final description = descriptionController.text.trim();
    if (description.isNotEmpty) queryParams['query.description'] = description;

    final editorFirstName = editorFirstNameController.text.trim();
    final editorLastName = editorLastNameController.text.trim();
    if (editorFirstName.isNotEmpty || editorLastName.isNotEmpty) {
      final editor = '$editorFirstName $editorLastName'.trim();
      queryParams['query.editor'] = editor;
    }

    final eventAcronym = eventAcronymController.text.trim();
    if (eventAcronym.isNotEmpty) {
      queryParams['query.event-acronym'] = eventAcronym;
    }

    final eventLocation = eventLocationController.text.trim();
    if (eventLocation.isNotEmpty) {
      queryParams['query.event-location'] = eventLocation;
    }

    final eventName = eventNameController.text.trim();
    if (eventName.isNotEmpty) queryParams['query.event-name'] = eventName;

    final eventSponsor = eventSponsorController.text.trim();
    if (eventSponsor.isNotEmpty) {
      queryParams['query.event-sponsor'] = eventSponsor;
    }

    final eventTheme = eventThemeController.text.trim();
    if (eventTheme.isNotEmpty) queryParams['query.event-theme'] = eventTheme;

    final funderName = funderNameController.text.trim();
    if (funderName.isNotEmpty) queryParams['query.funder-name'] = funderName;

    final publisherLocation = publisherLocationController.text.trim();
    if (publisherLocation.isNotEmpty) {
      queryParams['query.publisher-location'] = publisherLocation;
    }

    final standardsBodyAcronym = standardsBodyAcronymController.text.trim();
    if (standardsBodyAcronym.isNotEmpty) {
      queryParams['query.standards-body-acronym'] = standardsBodyAcronym;
    }

    final standardsBodyName = standardsBodyNameController.text.trim();
    if (standardsBodyName.isNotEmpty) {
      queryParams['query.standards-body-name'] = standardsBodyName;
    }

    // Handle sorting options
    if (selectedSortBy != 0) {
      // Map the sortbyItems to the API request format
      final sortOptions = [
        '-',
        'created',
        'deposited',
        'indexed',
        'is-referenced-by-count',
        'issued',
        'published',
        'published-online',
        'published-print',
        'references-count',
        'relevance',
        'score',
        'updated'
      ];
      queryParams['sort'] = sortOptions[selectedSortBy];
    }

    if (selectedSortOrder != 0) {
      // Map the sortorderItems to the API request format
      final orderOptions = ['-', 'asc', 'desc'];
      queryParams['order'] = orderOptions[selectedSortOrder];
    }

    String? dateFilter;

    String formatDate(DateTime d) => d.toIso8601String().split('T')[0];

    if (_dateMode == 'after' && _createdAfter != null) {
      dateFilter = 'from-created-date:${formatDate(_createdAfter!)}';
    } else if (_dateMode == 'before' && _createdBefore != null) {
      dateFilter = 'until-created-date:${formatDate(_createdBefore!)}';
    } else if (_dateMode == 'between' &&
        _createdAfter != null &&
        _createdBefore != null) {
      dateFilter = 'from-created-date:${formatDate(_createdAfter!)},'
          'until-created-date:${formatDate(_createdBefore!)}';
    }

    if (dateFilter != null) {
      queryParams['filter'] = queryParams.containsKey('filter')
          ? '${queryParams['filter']},$dateFilter'
          : dateFilter;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final dbHelper = DatabaseHelper();
      if (saveQuery) {
        final queryName = queryNameController.text.trim();
        if (queryName != '') {
          String queryString = queryParams.entries
              .map((entry) =>
                  '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value.toString())}')
              .join('&');

          await dbHelper.saveSearchQuery(queryName, queryString, 'Crossref');
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.queryHasNoNameError)),
          );
          return;
        }
      }

      // Close the loading indicator
      Navigator.pop(context);

      // Navigate to the results screen
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ArticleSearchResultsScreen(
                  queryParams: queryParams,
                  source: 'Crossref',
                )),
      );
    } catch (error) {
      // Close the loading indicator
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noresultsfound)),
      );
      /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );*/
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Article title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: bibliographicController,
              decoration: InputDecoration(
                labelText: "Bibliographic",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // Author name fields
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: "Author's first name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: TextFormField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: "Author's last name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Affiliation field
            TextFormField(
              controller: affiliationController,
              decoration: InputDecoration(
                labelText: 'Affiliation',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _dateMode,
              onChanged: (value) {
                setState(() {
                  _dateMode = value!;
                  _createdAfter = null;
                  _createdBefore = null;
                });
              },
              items: [
                DropdownMenuItem(
                  value: 'none',
                  child: Text(AppLocalizations.of(context)!.noFilter),
                ),
                DropdownMenuItem(
                  value: 'after',
                  child: Text(AppLocalizations.of(context)!.publishedAfter),
                ),
                DropdownMenuItem(
                  value: 'before',
                  child: Text(AppLocalizations.of(context)!.publishedBefore),
                ),
                DropdownMenuItem(
                  value: 'between',
                  child: Text(AppLocalizations.of(context)!.publishedBetween),
                ),
              ],
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.publicationDate,
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 8),

            if (_dateMode == 'after' || _dateMode == 'between')
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListTile(
                  title: Text(_createdAfter == null
                      ? AppLocalizations.of(context)!.selectStartDate
                      : _createdAfter!.toIso8601String().split('T')[0]),
                  trailing: Icon(Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary),
                  onTap: () => _pickDate(context, true),
                ),
              ),

            if (_dateMode == 'before' || _dateMode == 'between')
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListTile(
                  title: Text(_createdBefore == null
                      ? AppLocalizations.of(context)!.selectEndDate
                      : _createdBefore!.toIso8601String().split('T')[0]),
                  trailing: Icon(Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary),
                  onTap: () => _pickDate(context, false),
                ),
              ),
            SizedBox(height: 16),
            // Sort by and sort order fields
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Sort by',
                    ),
                    initialValue: selectedSortBy,
                    isExpanded: true,
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedSortBy = newValue ?? 0;
                      });
                    },
                    items: sortbyItems,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Sort order',
                    ),
                    initialValue: selectedSortOrder,
                    isExpanded: true,
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedSortOrder = newValue ?? 0;
                      });
                    },
                    items: sortorderItems,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Collapsible section that shows more search options
            ExpansionTile(
              title: Text(AppLocalizations.of(context)!.moreOptions),
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
                SizedBox(height: 8),
                // Publisher field
                TextFormField(
                  controller: publisherController,
                  decoration: InputDecoration(
                    labelText: 'Publisher',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: degreeController,
                  decoration: InputDecoration(
                    labelText: "Degree",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: editorFirstNameController,
                        decoration: InputDecoration(
                          labelText: "Editor first name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: TextFormField(
                        controller: editorLastNameController,
                        decoration: InputDecoration(
                          labelText: "Editor last name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: eventAcronymController,
                  decoration: InputDecoration(
                    labelText: "Event acronym",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: eventLocationController,
                  decoration: InputDecoration(
                    labelText: "Event location",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: eventNameController,
                  decoration: InputDecoration(
                    labelText: "Event name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: eventSponsorController,
                  decoration: InputDecoration(
                    labelText: "Event sponsor",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: eventThemeController,
                  decoration: InputDecoration(
                    labelText: "Event theme",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: funderNameController,
                  decoration: InputDecoration(
                    labelText: "Funder name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: publisherLocationController,
                  decoration: InputDecoration(
                    labelText: "Publisher location",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: standardsBodyAcronymController,
                  decoration: InputDecoration(
                    labelText: "Standards body acronym",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: standardsBodyNameController,
                  decoration: InputDecoration(
                    labelText: "Standards body name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.saveQuery,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Switch(
              value: saveQuery,
              onChanged: (bool value) {
                setState(() {
                  saveQuery = value;
                });
              },
            ),
            SizedBox(height: 8),
            if (saveQuery)
              TextFormField(
                controller: queryNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.queryName,
                  border: OutlineInputBorder(),
                ),
              ),
            SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
