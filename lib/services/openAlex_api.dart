import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:wispar/models/openAlex_works_models.dart';
import 'package:wispar/models/crossref_journals_works_models.dart'
    as journalWorks;
import 'package:wispar/models/openalex_domain_models.dart';

class OpenAlexApi {
  static const String baseUrl = 'https://api.openalex.org';
  static const String worksEndpoint = '/works?';
  static String? apiKey;

  static Future<List<journalWorks.Item>> getOpenAlexWorksByQuery(
      String query,
      int scope,
      String? sortField,
      String? sortOrder,
      String? dateFilter,
      String? issnFilter,
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
    if (issnFilter != null && issnFilter.isNotEmpty) {
      if (filterPart.isEmpty) {
        filterPart = 'filter=$issnFilter';
      } else {
        filterPart += ',$issnFilter';
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

  static Future<List<OpenAlexDomain>> getDomains() async {
    final prefs = await SharedPreferences.getInstance();
    apiKey = prefs.getString('openalex_api_key');

    final apiUrl = '$baseUrl/domains?per_page=50&select=id,display_name,fields'
        '${apiKey != null && apiKey!.isNotEmpty ? '&api_key=$apiKey' : ''}';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      final results = (jsonResponse['results'] as List?)
              ?.map((item) => OpenAlexDomain.fromJson(item))
              .toList() ??
          [];

      return results;
    } else {
      throw Exception('Failed to fetch domains: ${response.reasonPhrase}');
    }
  }

  static Future<List<OpenAlexSubfield>> getSubfieldsByFieldId(
      String fieldId) async {
    final prefs = await SharedPreferences.getInstance();
    apiKey = prefs.getString('openalex_api_key');

    final apiUrl = '$baseUrl/subfields?per_page=100'
        '&filter=field.id:$fieldId'
        '&select=id,display_name,topics'
        '${apiKey != null && apiKey!.isNotEmpty ? '&api_key=$apiKey' : ''}';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      final results = (jsonResponse['results'] as List?)
              ?.map((item) => OpenAlexSubfield.fromJson(item))
              .toList() ??
          [];

      return results;
    } else {
      throw Exception('Failed to fetch subfields: ${response.reasonPhrase}');
    }
  }

  static Future<OpenAlexJournalPage> getJournalsByTopic({
    String? domainId,
    String? fieldId,
    String? subfieldId,
    String? topicId,
    required int page,
    int perPage = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    apiKey = prefs.getString('openalex_api_key');

    String? filter;

    if (topicId != null) {
      final short = topicId.split('/').last;

      if (topicId.contains('/T')) {
        filter = 'primary_topic.id:$short';
      } else if (topicId.contains('/subfields/')) {
        filter = 'primary_topic.subfield.id:$short';
      } else if (topicId.contains('/fields/')) {
        filter = 'primary_topic.field.id:$short';
      } else if (topicId.contains('/domains/')) {
        filter = 'primary_topic.domain.id:$short';
      }
    } else {
      throw Exception("No topic level selected");
    }

    /* Since there's no direct way to get journals by topics in OpenAlex,
       I first group by a bunch of articles based on their domain, field,
       subfield, topic to extract ISSNs. Groupby are currently limited to 200 
       results so I applied a few extra filters to narrow the results down
    */
    final groupUrl = '$baseUrl/works'
        '?filter=$filter,primary_location.source.type:journal,primary_location.source.has_issn:true'
        '&group_by=primary_location.source.id'
        '&per_page=200'
        '${apiKey != null && apiKey!.isNotEmpty ? '&api_key=$apiKey' : ''}';
    final groupResponse = await http.get(Uri.parse(groupUrl));

    if (groupResponse.statusCode != 200) {
      throw Exception('Failed to group works: ${groupResponse.reasonPhrase}');
    }

    final groupJson = jsonDecode(groupResponse.body);

    final groups = (groupJson['group_by'] as List?)
            ?.map((g) => g['key'] as String?)
            .whereType<String>()
            .toList() ??
        [];

    if (groups.isEmpty) {
      return OpenAlexJournalPage(journals: [], hasMore: false);
    }

    final journalIds = groups.map((id) => id.split('/').last).toList();

    final start = (page - 1) * perPage;
    final end = start + perPage;

    if (start >= journalIds.length) {
      return OpenAlexJournalPage(
        journals: [],
        hasMore: false,
      );
    }

    final paginatedIds =
        journalIds.sublist(start, end.clamp(0, journalIds.length));
    /* I can then use the list of ISSNs extracted to get a list of journals */
    final journalsUrl = '$baseUrl/sources'
        '?filter=openalex:${paginatedIds.join('|')},type:journal'
        '&select=id,display_name,issn,type,host_organization_name'
        '${apiKey != null && apiKey!.isNotEmpty ? '&api_key=$apiKey' : ''}';

    final journalsResponse = await http.get(Uri.parse(journalsUrl));

    if (journalsResponse.statusCode != 200) {
      throw Exception(
          'Failed to fetch journals: ${journalsResponse.reasonPhrase}');
    }

    final journalsJson = jsonDecode(journalsResponse.body);

    final journals = (journalsJson['results'] as List?)
            ?.map((item) => TopicJournalResult.fromJson(item))
            .toList() ??
        [];

    final hasMore = end < journalIds.length;

    return OpenAlexJournalPage(
      journals: journals,
      hasMore: hasMore,
    );
  }
}

class OpenAlexJournalPage {
  final List<TopicJournalResult> journals;
  final bool hasMore;

  OpenAlexJournalPage({
    required this.journals,
    required this.hasMore,
  });
}
