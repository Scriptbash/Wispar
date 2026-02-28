import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/services/string_format_helper.dart';
import 'package:wispar/services/logs_helper.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/models/zotero_models.dart';

class ZoteroService {
  static const String baseUrl = 'https://api.zotero.org';
  static const String keyEndpoint = '/keys';
  static const String collectionEndpoint = '/collections';
  static const String itemsEndpoint = '/items';
  static const String groupsEndpoint = '/groups';
  static List<ZoteroCollection>? _cachedCollections;
  static bool _hasFetchedCollections = false;

  static void clearCollectionsCache() {
    _cachedCollections = null;
    _hasFetchedCollections = false;
  }

  // Function to load the API key from shared preferences
  static Future<String?> loadApiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('zoteroApiKey');
  }

  // Function to load the userId from shared preferences
  static Future<String?> loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('zoteroUserId');
  }

  // Function to get the userID required to make API requests
  static Future<int> getUserId(String apiKey) async {
    final response = await http.get(
      Uri.parse('$baseUrl$keyEndpoint/$apiKey'),
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data['userID'];
    } else {
      return 0;
    }
  }

  static Future<List<ZoteroCollection>> getAllCollections(
    String apiKey,
    String userId,
  ) async {
    // Return cached collections if already fetched
    if (_hasFetchedCollections && _cachedCollections != null) {
      return _cachedCollections!;
    }

    final personalResponse = await http.get(
      Uri.parse('$baseUrl/users/$userId$collectionEndpoint'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    List<ZoteroCollection> all = [];

    if (personalResponse.statusCode == 200) {
      final List<dynamic> raw = json.decode(personalResponse.body);
      all.addAll(raw.map((e) => ZoteroCollection.fromJson(e)).toList());
    }

    final groupCollections = await getGroupCollections(apiKey, userId);
    all.addAll(groupCollections);

    _cachedCollections = all;
    _hasFetchedCollections = true;

    return all;
  }

  // Function to get Zotero top collections
  static Future<List<ZoteroCollection>> getTopCollections(
      String apiKey, String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId$collectionEndpoint/top'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (response.statusCode == 200) {
      List<dynamic> rawData = json.decode(response.body);
      return rawData
          .map((collectionJson) => ZoteroCollection.fromJson(collectionJson))
          .toList();
    } else {
      throw Exception('Failed to load top collections');
    }
  }

  static Future<List<ZoteroCollection>> getGroupCollections(
    String apiKey,
    String userId,
  ) async {
    final logger = LogsService().logger;

    final groupResponse = await http.get(
      Uri.parse('$baseUrl/users/$userId$groupsEndpoint'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (groupResponse.statusCode != 200) {
      logger.info("No Zotero group found. Code: ${groupResponse.statusCode}");
      return [];
    }

    final List<dynamic> groups = json.decode(groupResponse.body);
    List<ZoteroCollection> allGroupCollections = [];

    for (var group in groups) {
      final groupId = group['id'].toString();

      final response = await http.get(
        Uri.parse('$baseUrl$groupsEndpoint/$groupId$collectionEndpoint'),
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      if (response.statusCode != 200) {
        logger.warning(
            "Group $groupId collections fetch failed: ${response.statusCode}");
        continue;
      }

      final List<dynamic> raw = json.decode(response.body);

      final collections = raw
          .map((e) => ZoteroCollection.fromJson(
                e,
                libraryId: groupId,
                isGroupLibrary: true,
              ))
          .toList();

      allGroupCollections.addAll(collections);
    }

    return allGroupCollections;
  }

  static Future<void> createZoteroCollection(
    String apiKey,
    String userId,
    String collectionName, {
    ZoteroCollection? parentCollection,
  }) async {
    final logger = LogsService().logger;

    String url;

    if (parentCollection != null &&
        parentCollection.isGroupLibrary &&
        parentCollection.libraryId != null) {
      url =
          'https://api.zotero.org/groups/${parentCollection.libraryId}$collectionEndpoint';
    } else {
      url = 'https://api.zotero.org/users/$userId$collectionEndpoint';
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode([
      {
        'name': collectionName,
        if (parentCollection?.key != null)
          'parentCollection': parentCollection!.key,
      }
    ]);

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      logger.info("Collection created successfully");
      clearCollectionsCache();
    } else {
      logger.severe(
        "Failed to create collection",
        "Status: ${response.statusCode}",
        StackTrace.fromString("Body: ${response.body}"),
      );
    }
  }

  static Future<void> createZoteroItem(String apiKey, String userId,
      ZoteroCollection targetCollection, Map<String, dynamic> itemData) async {
    final logger = LogsService().logger;
    String url;

    if (targetCollection.isGroupLibrary && targetCollection.libraryId != null) {
      url =
          'https://api.zotero.org/groups/${targetCollection.libraryId}$itemsEndpoint';
    } else {
      url = 'https://api.zotero.org/users/$userId$itemsEndpoint';
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode([itemData]);
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
    } else {
      logger.severe(
          "Failed to create Zotero item.",
          "Status code:${response.statusCode}",
          StackTrace.fromString("Response body: ${response.body}"));
    }
  }

  static Future<void> sendToZotero(
      BuildContext context,
      ZoteroCollection targetCollection,
      List<Map<String, dynamic>> authorsData,
      String title,
      String? abstract,
      String journalTitle,
      DateTime? publishedDate,
      String doi,
      List<String> issn) async {
    final logger = LogsService().logger;
    String? apiKey = await ZoteroService.loadApiKey();
    String? userId = await ZoteroService.loadUserId();

    logger.info("Sending article to Zotero...");

    try {
      if (apiKey != null && apiKey.isNotEmpty && userId != null) {
        // Prepare the article information
        Map<String, dynamic> articleData = {
          'data': {
            'itemType': 'journalArticle',
            'title': title,
            'abstractNote': abstract,
            'publicationTitle': journalTitle,
            'volume': '', //'Volume Number',
            'issue': '', //'Issue Number',
            'pages': '', //'Page Numbers',
            'date': publishedDate?.toIso8601String() ?? '',
            'series': '', //'Series',
            'seriesTitle': '', //'Series Title',
            'seriesText': '', //'Series Text',
            'journalAbbreviation': '', //'Journal Abbreviation',
            'language': '', //'Language',
            'DOI': doi,
            'ISSN':
                issn.first, // Todo check the format since ISSN is now a list
            'shortTitle': '', //'Short Title',
            'url': '',
            'accessDate': formatDate(DateTime.now()),
            'archive': '', //'Archive',
            'archiveLocation': '', //'Archive Location',
            'libraryCatalog': '', //'Library Catalog',
            'callNumber': '', //'Call Number',
            'rights': '', //'Rights',
            'extra': '', //'Extra Information',
            'creators': authorsData,
            'collections': [targetCollection.key],
            'tags': [
              {'tag': 'Wispar'},
            ],
            'relations': {},
          }
          /*'creatorTypes': [
          {'creatorType': 'author', 'primary': true},
          {'creatorType': 'contributor'},
          {'creatorType': 'editor'},
          {'creatorType': 'translator'},
          {'creatorType': 'reviewedAuthor'}
        ]*/
        };
        await ZoteroService.createZoteroItem(
            apiKey, userId, targetCollection, articleData);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.zoteroArticleSent),
          duration: const Duration(seconds: 1),
        ));
        logger.info("Successfully sent the article to Zotero");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            AppLocalizations.of(context)!.zoteroApiKeyEmpty,
          ),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e, stackTrace) {
      logger.severe("Failed to send item to Zotero", e, stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to send to Zotero"),
        ),
      );
    }
  }
}
