import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/crossref_journals_works_models.dart' as journalWorks;

class FeedApi {
  static const String baseUrl = 'https://api.crossref.org';
  static const String journalsEndpoint = '/journals';
  static const String worksEndpoint = '/works';
  static const String email = 'mailto=wispar-app@protonmail.com';

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
    String apiUrl = '$url?$queryString&rows=20&$email';

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
}
