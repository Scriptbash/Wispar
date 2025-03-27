import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/openAlex_works_models.dart';
import '../models/crossref_journals_works_models.dart' as journalWorks;

class OpenAlexApi {
  static const String baseUrl = 'https://api.openalex.org';
  static const String worksEndpoint = '/works?';
  static const String email = 'mailto=wispar-app@protonmail.com';
  static String? _currentQuery;

  static Future<List<journalWorks.Item>> getOpenAlexWorksByQuery(
      String query, int scope, String? sortField, String? sortOrder,
      {int page = 1} // Default to page 1
      ) async {
    _currentQuery = query;

    final scopeMap = {
      1: 'search=', // Everything
      2: 'filter=title_and_abstract.search:', // Title and Abstract
      3: 'filter=title.search:', // Title only
      4: 'filter=abstract.search:', // Abstract only
    };

    String searchField = scopeMap[scope] ?? 'search=';
    String sortBy = sortField != null ? '&sort=$sortField' : '';
    String orderBy = sortOrder != null ? ':$sortOrder' : '';

    String apiUrl =
        '$baseUrl$worksEndpoint$searchField$query$sortBy$orderBy&$email&page=$page';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final results = (jsonResponse['results'] as List?)
              ?.map((item) => OpenAlexWorks.fromJson(item))
              .toList() ??
          [];

      return results
          .map((result) => journalWorks.Item(
                title: result.title,
                abstract: result.abstract ?? '',
                journalTitle: result.journalTitle ?? '',
                publishedDate: result.publishedDate != null
                    ? DateTime.tryParse(result.publishedDate!) ??
                        DateTime(1970, 1, 1)
                    : DateTime(1970, 1, 1),
                doi: result.doi ?? '',
                authors: result.authors.map((fullName) {
                  List<String> parts = fullName.split(' ');
                  String given = parts.isNotEmpty ? parts.first : '';
                  String family =
                      parts.length > 1 ? parts.sublist(1).join(' ') : '';
                  return journalWorks.PublicationAuthor(
                      given: given, family: family);
                }).toList(),
                url: result.url ?? '',
                primaryUrl: result.url ?? '',
                license: '',
                licenseName: result.license ?? '',
                publisher: result.publisher ?? '',
                issn: result.issn?.isNotEmpty == true ? result.issn! : '',
              ))
          .toList();
    } else {
      throw Exception('Failed to fetch results: ${response.reasonPhrase}');
    }
  }
}
