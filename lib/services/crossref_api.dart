import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wispar/models/crossref_journals_models.dart' as Journals;
import 'package:wispar/models/crossref_journals_works_models.dart'
    as journalsWorks;

class CrossRefApi {
  static const String baseUrl = 'https://api.crossref.org';
  static const String worksEndpoint = '/works';
  static const String journalsEndpoint = '/journals';
  static const String mailto = 'wispar-app@protonmail.com';

  static Future<PaginatedResponse<Journals.Item>> queryJournalsByName({
    required String query,
    required String cursor,
  }) async {
    final uri = Uri.parse('$baseUrl$journalsEndpoint').replace(
      queryParameters: {
        'query': query,
        'rows': '30',
        'cursor': cursor,
        'mailto': mailto,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to query journals.');
    }

    final parsed = Journals.crossrefjournalsFromJson(response.body);

    return PaginatedResponse(
      items: parsed.message.items,
      nextCursor: parsed.message.nextCursor,
    );
  }

  static Future<Journals.Item?> queryJournalByISSN(String issn) async {
    final uri = Uri.parse('$baseUrl$journalsEndpoint/$issn')
        .replace(queryParameters: {'mailto': mailto});

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to query journal by ISSN.');
    }

    final data = json.decode(response.body);
    final message = data['message'];

    if (message == null) return null;

    return Journals.Item.fromJson(message, issn);
  }

  static Future<PaginatedResponse<journalsWorks.Item>> getJournalWorks({
    required List<String> issnList,
    required String cursor,
  }) async {
    final issnFilter = issnList.map((e) => 'issn:$e').join(',');

    final uri = Uri.parse('$baseUrl$worksEndpoint').replace(queryParameters: {
      'filter': issnFilter,
      'rows': '30',
      'sort': 'created',
      'order': 'desc',
      'cursor': cursor,
      'mailto': mailto,
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to query journal works.');
    }

    final parsed =
        journalsWorks.JournalWork.fromJson(json.decode(response.body));

    return PaginatedResponse(
      items: parsed.message.items,
      nextCursor: parsed.message.nextCursor,
    );
  }

  static Future<PaginatedResponse<journalsWorks.Item>> getWorksByQuery({
    required Map<String, dynamic> queryParams,
    required String cursor,
  }) async {
    final uri = Uri.parse('$baseUrl$worksEndpoint').replace(queryParameters: {
      ...queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      'rows': '50',
      'cursor': cursor,
      'mailto': mailto,
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch works.');
    }

    final parsed =
        journalsWorks.JournalWork.fromJson(json.decode(response.body));

    return PaginatedResponse(
      items: parsed.message.items,
      nextCursor: parsed.message.nextCursor,
    );
  }

  static Future<journalsWorks.Item> getWorkByDOI(String doi) async {
    final uri = Uri.parse('$baseUrl$worksEndpoint/$doi')
        .replace(queryParameters: {'mailto': mailto});

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to get work by DOI.');
    }

    final data = json.decode(response.body);
    final message = data['message'];

    if (message is! Map<String, dynamic>) {
      throw Exception('Invalid response format for DOI.');
    }

    return journalsWorks.Item.fromJson(message);
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final String? nextCursor;

  PaginatedResponse({
    required this.items,
    required this.nextCursor,
  });

  bool get hasMore => nextCursor != null && items.isNotEmpty;
}
