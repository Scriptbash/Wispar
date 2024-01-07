import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/crossref_journals_models.dart' as Journals;
import '../models/crossref_journals_works_models.dart' as journalsWorks;
import '../models/crossref_works_models.dart' as works;

class CrossRefApi {
  static const String baseUrl = 'https://api.crossref.org';
  static const String worksEndpoint = '/works';
  static const String journalsEndpoint = '/journals';
  static String? _cursor = '*';
  static String? _currentQuery;
  static String? _currentIssn;

  static Future<ListAndMore<Journals.Item>> queryJournals(String query) async {
    _currentQuery = query;
    String apiUrl = '$baseUrl$journalsEndpoint?query=$query&rows=50';

    if (_cursor != null) {
      apiUrl += '&cursor=$_cursor';
    }

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final crossrefJournals = Journals.crossrefjournalsFromJson(response.body);
      List<Journals.Item> items = crossrefJournals.message.items;

      // Update the global cursor only if it's not null
      if (crossrefJournals.message.nextCursor != null) {
        _cursor = crossrefJournals.message.nextCursor;
      }

      bool hasMoreResults =
          items.length < crossrefJournals.message.totalResults;

      return ListAndMore(items, hasMoreResults);
    } else {
      throw Exception('Failed to query journals');
    }
  }

  static Future<ListAndMore<journalsWorks.Item>> getJournalWorks(
      String issn) async {
    //_cursor = null; // Reset the cursor for a new query
    String apiUrl =
        '$baseUrl$journalsEndpoint/$issn/works?rows=25&sort=published&order=desc';

    if (_cursor != null) {
      apiUrl += '&cursor=$_cursor';
    }

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final crossrefJournals =
          journalsWorks.JournalWork.fromJson(json.decode(response.body));
      List<journalsWorks.Item> items = crossrefJournals.message?.items ?? [];
      // Update the global cursor only if it's not null
      if (crossrefJournals.message?.nextCursor != null) {
        _cursor = crossrefJournals.message!.nextCursor;
      }
      bool hasMoreResults =
          items.length < crossrefJournals.message.totalResults;

      //bool hasMoreResults = items.length <
      //    ((crossrefJournals.message?.totalResults is int)
      //        ? (crossrefJournals.message!.totalResults as int)
      //        : 0);

      return ListAndMore(items, hasMoreResults);
    } else {
      throw Exception('Failed to query journals');
    }
  }

  // Getter method for _cursor
  static String? get cursor => _cursor;

  // Add a method to get the current cursor
  static String? getCurrentCursor() {
    return _cursor;
  }

  static void resetCursor() {
    _cursor = '*';
  }

  static String? getCurrentQuery() {
    return _currentQuery;
  }

  static Future<works.Crossrefworks> getWorkByDOI(String doi) async {
    final response = await http.get(Uri.parse('$baseUrl$worksEndpoint/$doi'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final dynamic message = data['message'];

      if (message is Map<String, dynamic>) {
        return works.Crossrefworks.fromJson(message);
      } else {
        throw Exception('Invalid response format for work by DOI');
      }
    } else {
      throw Exception('Failed to load work by DOI');
    }
  }
}

class ListAndMore<T> {
  final List<T> list;
  final bool hasMore;

  ListAndMore(this.list, this.hasMore);
}
