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
  static String? _worksQueryCursor = '*';
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

      return ListAndMore(
        list: items,
        hasMore: hasMoreResults,
        totalResults: crossrefJournals.message.totalResults,
      );
    } else {
      throw Exception(
          'Failed to query journals by name. Status code: ${response.statusCode}');
    }
  }

  // Query journals by ISSN
  static Future<ListAndMore<Journals.Item>> queryJournalsByISSN(
      String query) async {
    String apiUrl = '$baseUrl$journalsEndpoint/$query&$email';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      var message = jsonResponse['message'];

      if (message != null) {
        Journals.Item item = Journals.Item.fromJson(message, query);

        return ListAndMore(
          list: [item],
          hasMore: false,
          totalResults: 0,
        );
      } else {
        throw Exception('Message object missing in response');
      }
    } else {
      throw Exception(
          'Failed to query journals by ISSN. Status code: ${response.statusCode}');
    }
  }

  // Query works for a specific journal by ISSN
  static Future<ListAndMore<journalsWorks.Item>> getJournalWorks(
      List<String> issn) async {
    final String issnFilter = issn.map((e) => 'issn:$e').join(',');
    String apiUrl =
        '$baseUrl$worksEndpoint?rows=30&sort=created&order=desc&$email&filter=$issnFilter';

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

      return ListAndMore(
        list: items,
        hasMore: hasMoreResults,
        totalResults: crossrefWorks.message.totalResults,
      );
    } else {
      throw Exception(
          'Failed to query journal works: Status code: ${response.statusCode}');
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

  static void resetWorksQueryCursor() {
    _worksQueryCursor = '*';
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
      throw Exception(
          'Failed to get work by DOI. Status code: ${response.statusCode}');
    }
  }

  static Future<ListAndMore<journalsWorks.Item>> getWorksByQuery(
      Map<String, dynamic> queryParams) async {
    String url = '$baseUrl$worksEndpoint';
    // Construct the query parameters string by iterating over the queryParams map
    String queryString = queryParams.entries
        .map((entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value.toString())}')
        .join('&');
    String apiUrl = '$url?$queryString&rows=50&$email';
    if (_worksQueryCursor != null) {
      apiUrl += '&cursor=$_worksQueryCursor';
    }
    final response = await http.get(Uri.parse(apiUrl));
    //print('$url?$queryString');

    if (response.statusCode == 200) {
      final responseData =
          journalsWorks.JournalWork.fromJson(json.decode(response.body));
      List<journalsWorks.Item> feedItems = responseData.message.items;
      _worksQueryCursor = responseData.message.nextCursor;
      bool hasMoreResults =
          _worksQueryCursor != null && _worksQueryCursor != "";
      return ListAndMore(
        list: feedItems,
        hasMore: hasMoreResults,
        totalResults: responseData.message.totalResults,
      );
    } else {
      throw Exception(
          'Failed to fetch results. Status code: ${response.statusCode}');
    }
  }
}

class ListAndMore<T> {
  final List<T> list;
  final bool hasMore;
  final int totalResults;

  ListAndMore({
    required this.list,
    required this.hasMore,
    required this.totalResults,
  });
}
