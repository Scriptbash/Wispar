import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/crossref_journals_models.dart' as Journals;
import '../models/crossref_journals_works_models.dart' as journalsWorks;

class CrossRefApi {
  static const String baseUrl = 'https://api.crossref.org';
  static const String worksEndpoint = '/works';
  static const String journalsEndpoint = '/journals';
  static const String email = 'mailto=wispar-app@protonmail.com';
  static String? _journalCursor = '*';
  static String? _journalWorksCursor = '*';
  static String? _currentQuery;

  // Query journals by name
  static Future<ListAndMore<Journals.Item>> queryJournalsByName(
      String query) async {
    _currentQuery = query;
    String apiUrl = '$baseUrl$journalsEndpoint?query=$query&rows=30&$email';

    if (_journalCursor != null) {
      apiUrl += '&cursor=$_journalCursor';
    }

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final crossrefJournals = Journals.crossrefjournalsFromJson(response.body);
      List<Journals.Item> items = crossrefJournals.message.items;

      // Update the journal cursor
      _journalCursor = crossrefJournals.message.nextCursor;

      // Use nextCursor to determine if there are more results
      bool hasMoreResults = _journalCursor != null && _journalCursor != "";

      return ListAndMore(items, hasMoreResults);
    } else {
      throw Exception('Failed to query journals');
    }
  }

  // Query journals by ISSN
  static Future<ListAndMore<Journals.Item>> queryJournalsByISSN(
      String query) async {
    String apiUrl = '$baseUrl$journalsEndpoint/$query&$email';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final crossrefJournals = Journals.crossrefjournalsFromJson(response.body);
      List<Journals.Item> items = crossrefJournals.message.items;

      // Update the journal cursor
      _journalCursor = crossrefJournals.message.nextCursor;

      // Use nextCursor to determine if there are more results
      bool hasMoreResults = _journalCursor != null && _journalCursor != "";

      return ListAndMore(items, hasMoreResults);
    } else {
      throw Exception('Failed to query journals');
    }
  }

  // Query works for a specific journal by ISSN
  static Future<ListAndMore<journalsWorks.Item>> getJournalWorks(
      String issn) async {
    String apiUrl =
        '$baseUrl$journalsEndpoint/$issn/works?rows=30&sort=created&order=desc&$email';

    if (_journalWorksCursor != null) {
      apiUrl += '&cursor=$_journalWorksCursor';
    }

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final crossrefWorks =
          journalsWorks.JournalWork.fromJson(json.decode(response.body));
      List<journalsWorks.Item> items = crossrefWorks.message.items;

      // Update the works cursor
      _journalWorksCursor = crossrefWorks.message.nextCursor;

      // Use nextCursor to determine if there are more results
      bool hasMoreResults =
          _journalWorksCursor != null && _journalWorksCursor != "";

      return ListAndMore(items, hasMoreResults);
    } else {
      throw Exception('Failed to query journal works');
    }
  }

  // Getter method for _journalCursor
  static String? get journalCursor => _journalCursor;

  // Getter method for _journalWorksCursor
  static String? get journalWorksCursor => _journalWorksCursor;

  static String? getCurrentJournalCursor() => _journalCursor;
  static String? getCurrentJournalWorksCursor() => _journalWorksCursor;

  static void resetJournalCursor() {
    _journalCursor = '*';
  }

  static void resetJournalWorksCursor() {
    _journalWorksCursor = '*';
  }

  static String? getCurrentQuery() {
    return _currentQuery;
  }

  static Future<journalsWorks.Item> getWorkByDOI(String doi) async {
    final response = await http.get(Uri.parse('$baseUrl$worksEndpoint/$doi'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final dynamic message = data['message'];

      if (message is Map<String, dynamic>) {
        return journalsWorks.Item.fromJson(message);
      } else {
        throw Exception('Invalid response format for work by DOI');
      }
    } else {
      throw Exception('Failed to load work by DOI');
    }
  }

  static Future<List<journalsWorks.Item>> getWorksByQuery(
      Map<String, dynamic> queryParams) async {
    String url = '$baseUrl$worksEndpoint';
    // Construct the query parameters string by iterating over the queryParams map
    String queryString = queryParams.entries
        .map((entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value.toString())}')
        .join('&');

    final response =
        await http.get(Uri.parse('$url?$queryString&rows=50&$email'));
    //print('$url?$queryString');

    if (response.statusCode == 200) {
      final responseData =
          journalsWorks.JournalWork.fromJson(json.decode(response.body));
      List<journalsWorks.Item> feedItems = responseData.message.items;
      return feedItems;
    } else {
      throw Exception('Failed to fetch results');
    }
  }
}

class ListAndMore<T> {
  final List<T> list;
  final bool hasMore;

  ListAndMore(this.list, this.hasMore);
}
