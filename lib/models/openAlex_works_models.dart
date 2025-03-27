import 'dart:convert';

class OpenAlexWorks {
  final String title;
  final String? doi;
  final String? url;
  final List<String> authors;
  final String? abstract;
  final String? journalTitle;
  final String? publishedDate;
  final String? landingPageUrl;
  final String? displayName;
  final List<String>? issn;
  final String? publisher;
  final String? license;

  OpenAlexWorks({
    required this.title,
    this.doi,
    this.url,
    required this.authors,
    this.abstract,
    this.journalTitle,
    this.publishedDate,
    this.landingPageUrl,
    this.displayName,
    this.issn,
    this.publisher,
    this.license,
  });

  factory OpenAlexWorks.fromJson(Map<String, dynamic> json) {
    final primaryLocation = json['primary_location'];

    String? extractedDoi;
    if (json['doi'] != null && json['doi'].startsWith('https://doi.org/')) {
      extractedDoi = json['doi'].replaceFirst('https://doi.org/', '');
    }

    return OpenAlexWorks(
      title: json['title'] ?? 'Untitled',
      doi: extractedDoi ?? json['doi'],
      url: primaryLocation?['landing_page_url'],
      authors: (json['authorships'] as List?)
              ?.map((a) => a['author']?['display_name'] as String?)
              .whereType<String>()
              .toList() ??
          [],
      abstract: reconstructAbstract(json['abstract_inverted_index']),
      journalTitle: cleanText(
        primaryLocation?['source']?['display_name'],
      ),
      publishedDate: json['publication_date'],
      issn: (primaryLocation?['source']?['issn'] as List?)
          ?.map((issn) => issn as String)
          .toList(),
      publisher: primaryLocation?['source']?['host_organization_name'],
      license: primaryLocation?["license"],
    );
  }
}

String? reconstructAbstract(Map<String, dynamic>? invertedIndex) {
  if (invertedIndex == null) return null;

  int maxIndex = invertedIndex.values
      .expand((positions) => positions)
      .reduce((a, b) => a > b ? a : b);

  List<String> words = List<String>.filled(maxIndex + 1, '', growable: false);

  invertedIndex.forEach((word, positions) {
    for (int pos in positions) {
      words[pos] = word;
    }
  });

  String cleanedAbstract = words.join(' ');
  cleanedAbstract = cleanedAbstract
      .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
      .replaceAll(RegExp(r'^\s*abstract[:.\s]*', caseSensitive: false),
          '') // Remove leading "Abstract"
      .trim();

  return cleanedAbstract;
}

String cleanText(String? text) {
  if (text == null) return '';
  try {
    String decoded = utf8.decode(text.codeUnits, allowMalformed: true);
    return decoded.replaceAll(RegExp(r'[^\x20-\x7E]'), ''); // Remove non-ASCII
  } catch (e) {
    return text;
  }
}
