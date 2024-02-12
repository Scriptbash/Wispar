import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Zotero {
  final String doiUrl;
  final String pdfUrl;

  Zotero({required this.doiUrl, required this.pdfUrl});

  factory Zotero.fromJson(Map<String, dynamic> json) {
    return Zotero(
      doiUrl: json['doi_url'] ?? '',
      pdfUrl: json['best_oa_location']?['url_for_pdf'] ?? '',
    );
  }
}

class ZoteroCollection {
  final String key;
  final String name;
  //final bool isSubCollection;

  ZoteroCollection({
    required this.key,
    required this.name,
    //this.isSubCollection = false,
  });

  ZoteroCollection.subCollection({
    required String key,
    required String name,
  }) : this(
          key: key,
          name: name,
        ); //isSubCollection: true);

  factory ZoteroCollection.fromJson(Map<String, dynamic> json) {
    return ZoteroCollection(
      key: json['key'] ?? '',
      name: json['data']['name'] ?? '',
    );
  }
}

class ZoteroItem {
  final String key;
  final String name;
  /* final String itemType;
  final String title;
  final String abstractNote;
  final String publiciationTitle;
  final String doi;
  final String url;*/

  ZoteroItem({
    required this.key,
    required this.name,
  });
}

class ZoteroService {
  static const String baseUrl = 'https://api.zotero.org';
  static const String keyEndpoint = '/keys';
  static const String collectionEndpoint = '/collections';
  static const String itemsEndpoint = '/items';

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

  // Function to get Zotero top collections
  static Future<List<ZoteroCollection>> getTopCollections(
      String apiKey, String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId$collectionEndpoint/top'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );
    if (response.statusCode == 200) {
      List<dynamic> rawData = json.decode(response.body);
      List<ZoteroCollection> collections = rawData
          .map((collectionJson) => ZoteroCollection.fromJson(collectionJson))
          .toList();

      return collections;
    } else {
      //print('Failed to load collections. Status code: ${response.statusCode}');
      //print('Response body: ${response.body}');
      throw Exception('Failed to load collections');
    }
  }

  // Function to get Zotero subcollections
  static Future<List<ZoteroCollection>> getSubCollections(
    String apiKey,
    String userId,
    String collectionKey,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/users/$userId$collectionEndpoint/$collectionKey$collectionEndpoint',
      ),
      headers: {'Authorization': 'Bearer $apiKey'},
    );
    if (response.statusCode == 200) {
      List<dynamic> rawData = json.decode(response.body);
      List<ZoteroCollection> collections = rawData
          .map((collectionJson) => ZoteroCollection.subCollection(
                key: collectionJson['key'] ?? '',
                name: collectionJson['data']['name'] ?? '',
              ))
          .toList();
      return collections;
    } else {
      // Handle error
      //print('Failed to load collections. Status code: ${response.statusCode}');
      //print('Response body: ${response.body}');
      throw Exception('Failed to load collections');
    }
  }

  static Future<void> createZoteroCollection(
      String apiKey, String userId, String collectionName) async {
    final url = 'https://api.zotero.org/users/$userId/collections';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      //'Zotero-Write-Token': apiKey,
    };
    final body = jsonEncode([
      {
        'name': collectionName,
        //'parentCollection': parentCollectionKey,
      }
    ]);

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      // print('Collection created successfully');
    } else {
      // print('Failed to create collection. Status code: ${response.statusCode}');
      // print('Response body: ${response.body}');
    }
  }

  static Future<void> createZoteroItem(
      String apiKey, String userId, Map<String, dynamic> itemData) async {
    final url = 'https://api.zotero.org/users/$userId/items';
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
      //print('Article item created successfully');
      //print(response.body);
    } else {
      //print(
      //    'Failed to create article item. Status code: ${response.statusCode}');
      //print('Response body: ${response.body}');
    }
  }
}
