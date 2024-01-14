import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/crossref_journals_works_models.dart' as journalWorks;

class FeedApi {
  static const String baseUrl = 'https://api.crossref.org';
  static const String journalsEndpoint = '/journals';

  static Future<List<journalWorks.Item>> getRecentFeed(String issn) async {
    final response = await http.get(Uri.parse(
        '$baseUrl$journalsEndpoint/$issn/works?rows=100&sort=created&order=desc'));

    if (response.statusCode == 200) {
      final responseData =
          journalWorks.JournalWork.fromJson(json.decode(response.body));
      List<journalWorks.Item> feedItems = responseData.message.items;
      return feedItems;
    } else {
      throw Exception('Failed to fetch recent feed');
    }
  }
}
