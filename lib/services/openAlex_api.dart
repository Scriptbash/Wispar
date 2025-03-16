import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/openAlex_works_models.dart';

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
