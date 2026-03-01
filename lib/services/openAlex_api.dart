import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:wispar/models/openAlex_works_models.dart';
import 'package:wispar/models/crossref_journals_works_models.dart'
    as journalWorks;

class OpenAlexApi {
  static const String baseUrl = 'https://api.openalex.org';
  static const String worksEndpoint = '/works?';
  static String? apiKey;

  static Future<List<journalWorks.Item>> getOpenAlexWorksByQuery(String query,
      int scope, String? sortField, String? sortOrder, String? dateFilter,
      {int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    apiKey = prefs.getString('openalex_api_key');

    Map<int, String> scopeMap = {
      1: '', // Everything
      2: 'title_and_abstract.search:', // Title and Abstract
      3: 'title.search:', // Title only
      4: 'abstract.search:', // Abstract only
    };

    String searchPart;
    String filterPart = '';

    if (scope == 1) {
      searchPart = 'search=$query';
    } else {
      searchPart = '';
      filterPart = 'filter=${scopeMap[scope]}$query';
    }

    if (dateFilter != null && dateFilter.isNotEmpty) {
      if (filterPart.isEmpty) {
        filterPart = 'filter=$dateFilter';
      } else {
        filterPart += ',$dateFilter';
      }
    }

    String sortPart = '';
    if (sortField != null && sortOrder != null) {
      sortPart = '&sort=$sortField:$sortOrder';
    }

    String apiUrl = '$baseUrl/works?$searchPart'
        '${filterPart.isNotEmpty ? '&$filterPart' : ''}'
        '$sortPart'
        '${apiKey != null && apiKey!.isNotEmpty ? '&api_key=$apiKey' : ''}'
        '&page=$page';

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
                issn: result.issn ?? [],
              ))
          .toList();
    } else {
      throw Exception('Failed to fetch results: ${response.reasonPhrase}');
    }
  }
}
