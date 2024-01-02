import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/crossref_journals_models.dart' as Journals;
import '../models/crossref_works_models.dart';

class CrossRefApi {
  static const String baseUrl = 'https://api.crossref.org';
  static const String worksEndpoint = '/works';
  static const String journalsEndpoint = '/journals';

  static Future<List<Journals.Item>> queryJournals(String query) async {
    final response = await http
        .get(Uri.parse('$baseUrl$journalsEndpoint?query=$query&rows=50'));

    if (response.statusCode == 200) {
      final crossrefJournals = Journals.crossrefJournalsFromJson(response.body);
      List<Journals.Item> items = crossrefJournals.message.items;
      return items;
    } else {
      throw Exception('Failed to query journals');
    }
  }

  static Future<CrossrefWorks> getWorkByDOI(String doi) async {
    final response = await http.get(Uri.parse('$baseUrl$worksEndpoint/$doi'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final dynamic message = data['message'];

      if (message is Map<String, dynamic>) {
        return CrossrefWorks.fromJson(message);
      } else {
        throw Exception('Invalid response format for work by DOI');
      }
    } else {
      throw Exception('Failed to load work by DOI');
    }
  }

  static Future<List<CrossrefWorks>> queryWorks(String query) async {
    final response =
        await http.get(Uri.parse('$baseUrl$worksEndpoint?query=hydrology'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['message']['items'];

      return items.map((item) => CrossrefWorks.fromJson(item)).toList();
    } else {
      throw Exception('Failed to query works');
    }
  }
}
