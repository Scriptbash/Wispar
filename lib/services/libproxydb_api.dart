import 'dart:convert';
import 'package:http/http.dart' as http;

class ProxyData {
  final String name;
  final String url;

  ProxyData({required this.name, required this.url});

  factory ProxyData.fromJson(Map<String, dynamic> json) {
    return ProxyData(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class ProxyService {
  static Future<List<ProxyData>> fetchProxies() async {
    final response =
        await http.get(Uri.parse('https://libproxy-db.org/proxies.json'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);

      return jsonList.map((json) => ProxyData.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load proxy data');
    }
  }
}
