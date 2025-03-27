import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/crossref_journals_works_models.dart' as journalWorks;
import '../models/openAlex_works_models.dart';

class FeedApi {
  static const String baseUrl = 'https://api.crossref.org';
  static const String journalsEndpoint = '/journals';
  static const String worksEndpoint = '/works';
  static const String email = 'mailto=wispar-app@protonmail.com';

  static const String baseUrlOpenAlex = 'https://api.openalex.org';
  static const String worksEndpointOpenAlex = '/works?';

  static Future<List<journalWorks.Item>> getRecentFeed(String issn) async {
    final response = await http.get(Uri.parse(
        '$baseUrl$journalsEndpoint/$issn/works?rows=100&sort=created&order=desc&$email'));

    if (response.statusCode == 200) {
      final responseData =
          journalWorks.JournalWork.fromJson(json.decode(response.body));
      List<journalWorks.Item> feedItems = responseData.message.items;
      return feedItems;
    } else {
      throw Exception('Failed to fetch recent feed');
    }
  }

  static Future<List<journalWorks.Item>> getSavedQueryWorks(
      Map<String, dynamic> queryParams) async {
    String url = '$baseUrl$worksEndpoint';
    String queryString = queryParams.entries
        .map((entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value.toString())}')
        .join('&');
    String apiUrl = '$url?$queryString&rows=50&$email';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final responseData =
          journalWorks.JournalWork.fromJson(json.decode(response.body));
      List<journalWorks.Item> feedItems = responseData.message.items;
      return feedItems;
    } else {
      throw Exception('Failed to fetch results');
    }
  }

  static Future<List<journalWorks.Item>> getSavedQueryOpenAlex(
      String query) async {
    final url = Uri.parse(
        '$baseUrlOpenAlex$worksEndpointOpenAlex$query&per-page=50&$email');

    final response = await http.get(url);

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
                issn: result.issn?.isNotEmpty == true ? result.issn!.last : '',
              ))
          .toList();
    } else {
      throw Exception('Failed to fetch results: ${response.reasonPhrase}');
    }
  }
}
