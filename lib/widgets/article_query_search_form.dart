import 'package:flutter/material.dart';
import '../services/crossref_api.dart';
import '../screens/article_search_results_screen.dart';

class QuerySearchForm extends StatefulWidget {
  // The key allows to access the state of the form from outside
  const QuerySearchForm({Key? key}) : super(key: key);

  @override
  QuerySearchFormState createState() => QuerySearchFormState();
}

class QuerySearchFormState extends State<QuerySearchForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
    super.dispose();
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
    if (publisher.isNotEmpty) queryParams['query.publisher'] = publisher;

    final affiliation = affiliationController.text.trim();
    if (affiliation.isNotEmpty) queryParams['query.affiliation'] = affiliation;

    final bibliographic = bibliographicController.text.trim();
    if (bibliographic.isNotEmpty)
      queryParams['query.bibliographic'] = bibliographic;

    final degree = degreeController.text.trim();
    if (degree.isNotEmpty) queryParams['query.degree'] = degree;

    final description = descriptionController.text.trim();
    if (description.isNotEmpty) queryParams['query.description'] = description;

    // Handle sorting options
    if (selectedSortBy != 0) queryParams['query.sortBy'] = selectedSortBy;
    if (selectedSortOrder != 0)
      queryParams['query.sortOrder'] = selectedSortOrder;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Makes the API call
      final response = await CrossRefApi.getWorksByQuery(queryParams);
      print(response);

      // Close the loading indicator
      Navigator.pop(context);

      // Navigate to the results screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleSearchResultsScreen(
            searchResults: response,
          ),
        ),
      );
    } catch (error) {
      // Close the loading indicator
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Article Title',
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
              // Publisher field
              TextFormField(
                controller: publisherController,
                decoration: InputDecoration(
                  labelText: 'Publisher',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              // Sort by and sort order fields
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
                        labelText: 'Sort order',
                      ),
                      value: selectedSortOrder,
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
                title: Text('More options'),
                leading: Icon(
                  isAdvancedSearchVisible
                      ? Icons.expand_less
                      : Icons.expand_more,
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
              SizedBox(height: 16),
              Text(
                'Save this query',
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
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
