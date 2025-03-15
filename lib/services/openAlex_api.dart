import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchResult {
  final String title;
  final String? doi;
  final String? url;
  final List<String> authors;
  final String? abstract;
  final String? journalTitle;
  final String? publishedDate;
  final String? landingPageUrl;
  final String? displayName;
  final List<String>? issn;
  final String? publisher;
  final String? license;

  SearchResult({
    required this.title,
    this.doi,
    this.url,
    required this.authors,
    this.abstract,
    this.journalTitle,
    this.publishedDate,
    this.landingPageUrl,
    this.displayName,
    this.issn,
    this.publisher,
    this.license,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final primaryLocation = json['primary_location'];

    String? extractedDoi;
    if (json['doi'] != null && json['doi'].startsWith('https://doi.org/')) {
      extractedDoi = json['doi'].replaceFirst('https://doi.org/', '');
    }

    return SearchResult(
      title: json['title'] ?? 'Untitled',
      doi: extractedDoi ?? json['doi'],
      url: primaryLocation?['landing_page_url'],
      authors: (json['authorships'] as List?)
              ?.map((a) => a['author']?['display_name'] as String?)
              .whereType<String>()
              .toList() ??
          [],
      abstract: json['abstract'],
      journalTitle: primaryLocation?['source']?['display_name'],
      publishedDate: json['publication_date'],
      issn: (primaryLocation?['source']?['issn'] as List?)
          ?.map((issn) => issn as String)
          .toList(),
      publisher: primaryLocation?['source']?['host_organization_name'],
      license: primaryLocation?["license"],
    );
  }
}

class OpenAlexApi {
  static const String baseUrl = 'https://api.openalex.org';
  static const String worksEndpoint = '/works?';
  static const String email = 'mailto=wispar-app@protonmail.com';

  static Future<List<SearchResult>> getOpenAlexWorksByQuery(
    String query,
    int scope,
    String? sortField,
    String? sortOrder,
  ) async {
    final scopeMap = {
      1: 'search=', // Everything
      2: 'filter=title_and_abstract.search:', // Title and Abstract
      3: 'filter=title.search:', // Title only
      4: 'filter=abstract.search:', // Abstract only
    };
    String selectedSortBy = '';
    String selectedSortOrder = '';

    String searchField = scopeMap[scope] ?? 'search=';

    if (sortField != null) {
      selectedSortBy = '&sort=$sortField';
    }
    if (sortOrder != null) {
      selectedSortOrder = ':$sortOrder';
    }
    final url = Uri.parse(
        '$baseUrl$worksEndpoint$searchField$query$selectedSortBy$selectedSortOrder&$email');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final results = (jsonResponse['results'] as List?)
              ?.map((item) => SearchResult.fromJson(item))
              .toList() ??
          [];
      return results;
    } else {
      throw Exception('Failed to fetch results: ${response.reasonPhrase}');
    }
  }
}
