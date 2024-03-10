import 'dart:convert';
import 'package:http/http.dart' as http;

class Unpaywall {
  final String doiUrl;
  final String pdfUrl;

  Unpaywall({required this.doiUrl, required this.pdfUrl});

  factory Unpaywall.fromJson(Map<String, dynamic> json) {
    return Unpaywall(
      doiUrl: json['doi_url'] ?? '',
      pdfUrl: json['best_oa_location']?['url_for_pdf'] ?? '',
    );
  }
}

class UnpaywallService {
  static Future<Unpaywall> checkAvailability(String doi) async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.unpaywall.org/v2/$doi?email=wispar-app@protonmail.com'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        return Unpaywall.fromJson(jsonResponse);
      } else {
        return Unpaywall.fromJson({});
      }
    } catch (e) {
      return Unpaywall.fromJson({});
    }
  }
}
