class JournalWork {
  final String status;
  final String messageType;
  final String messageVersion;
  final Message message;

  JournalWork({
    required this.status,
    required this.messageType,
    required this.messageVersion,
    required this.message,
  });

  factory JournalWork.fromJson(Map<String, dynamic> json) {
    return JournalWork(
      status: json['status'] ?? '',
      messageType: json['message-type'] ?? '',
      messageVersion: json['message-version'] ?? '',
      message: Message.fromJson(json['message'] ?? {}),
    );
  }
}

class Message {
  final int itemsPerPage;
  final Query query;
  final int totalResults;
  final String nextCursor;
  final List<Item> items;

  Message({
    required this.itemsPerPage,
    required this.query,
    required this.totalResults,
    required this.nextCursor,
    required this.items,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      itemsPerPage: json['items-per-page'] ?? 0,
      query: Query.fromJson(json['query'] ?? {}),
      totalResults: json['total-results'] ?? 0,
      nextCursor: json['next-cursor'] ?? '',
      items: List<Item>.from(
          (json['items'] ?? []).map((item) => Item.fromJson(item))),
    );
  }
}

class Query {
  final int startIndex;
  final String searchTerms;

  Query({
    required this.startIndex,
    required this.searchTerms,
  });

  factory Query.fromJson(Map<String, dynamic> json) {
    return Query(
      startIndex: json['start-index'] ?? 0,
      searchTerms: json['search-terms'] ?? '',
    );
  }
}

class Item {
  final String publisher;
  final String abstract;
  final String title;
  final DateTime publishedDate;
  final String journalTitle;
  final String doi;
  final List<PublicationAuthor> authors;
  final String url;
  final String primaryUrl;
  final String license;
  final String licenseName;
  final String issn;

  Item({
    required this.publisher,
    required this.abstract,
    required this.title,
    required this.publishedDate,
    required this.journalTitle,
    required this.doi,
    required this.authors,
    required this.url,
    required this.primaryUrl,
    required this.license,
    required this.licenseName,
    required this.issn,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    List<PublicationAuthor> authors = [];
    if (json['author'] != null && json['author'] is List) {
      authors = (json['author'] as List<dynamic>)
          .map((authorJson) => PublicationAuthor.fromJson(authorJson))
          .toList();
    }

    String licenseUrl = '';
    String licenseName = '';

    // Check if 'license' is available in the JSON and is a non-empty list
    if (json.containsKey('license') &&
        json['license'] is List &&
        (json['license'] as List).isNotEmpty) {
      final licenseData = json['license'][0];
      if (licenseData is Map<String, dynamic> &&
          licenseData.containsKey('URL')) {
        licenseUrl = licenseData['URL'];
        licenseName = licenseNames[normalizeLicenseUrl(licenseUrl)] ?? '';
      }
    }

    String journalTitle = '';
    if (json['container-title'] is List &&
        (json['container-title'] as List).isNotEmpty) {
      journalTitle = (json['container-title'] as List<dynamic>).first ?? '';
    }

    String issn = '';
    if (json['ISSN'] != null) {
      if (json['ISSN'] is List && (json['ISSN'] as List).isNotEmpty) {
        issn = (json['ISSN'] as List<dynamic>).last ?? '';
      } else {
        issn = json['ISSN'] ?? '';
      }
    }

    return Item(
      publisher: json['publisher'] ?? '',
      abstract: _cleanAbstract(json['abstract'] ?? ''),
      title: _extractTitle(json['title']),
      publishedDate: _parseDate(json['created']),
      journalTitle: journalTitle,
      doi: json['DOI'] ?? '',
      authors: authors,
      url: json['URL'] ?? '',
      primaryUrl: json['resource']['primary']['URL'] ?? '',
      license: licenseUrl,
      licenseName: licenseName,
      issn: issn,
    );
  }
  static Map<String, String> licenseNames = {
    'https://creativecommons.org/licenses/by/4.0':
        'Creative Commons Attribution 4.0',
    'https://creativecommons.org/licenses/by-sa/4.0':
        'Creative Commons Attribution-ShareAlike 4.0 International',
    'https://creativecommons.org/licenses/by-nc/4.0':
        'Creative Commons Attribution-NonCommercial 4.0 International',
    'https://creativecommons.org/licenses/by-nc-sa/4.0':
        'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International',
    'https://creativecommons.org/licenses/by-nd/4.0':
        'Creative Commons Attribution-NoDerivatives 4.0 International',
    'https://www.gnu.org/licenses/agpl-3.0.html':
        'GNU Affero General Public License v3.0',
    'https://www.gnu.org/licenses/gpl-3.0.html':
        'GNU General Public License v3.0',
    'https://www.gnu.org/licenses/lgpl-3.0.html':
        'GNU Lesser General Public License v3.0',
    'https://opensource.org/licenses/MIT': 'MIT License',
    'https://opensource.org/licenses/Apache-2.0': 'Apache License 2.0',
    'https://www.elsevier.com/tdm/userlicense/1.0':
        'Elsevier Text and Data Mining (TDM) License',
    'https://www.springer.com/tdm': 'Springer Nature TDM policy',
    'https://www.springernature.com/gp/researchers/text-and-data-mining':
        'Springer Nature TDM policy',
    'https://onlinelibrary.wiley.com/termsAndConditions#vor':
        'Wiley Online Library Terms of Use',
    'https://doi.wiley.com/10.1002/tdm_license_1.1': 'Wiley TDM policy',
    'https://iopscience.iop.org/page/copyright': 'IOP copyright protection',
    'https://ieeexplore.ieee.org/Xplorehelp/downloads/license-information/IEEE.html':
        'IEE copyright policy',
    'https://creativecommons.org/licenses/by-nc-nd/4.0':
        'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International',
    'https://www.nrcresearchpress.com/page/about/CorporateTextAndDataMining':
        'Canadian Science Publishing TDM policy'
  };

  static String _cleanAbstract(String rawAbstract) {
    rawAbstract = rawAbstract
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'^\s*abstract[:.\s]*', caseSensitive: false),
            '') // Remove leading "Abstract"
        .trim();

    return rawAbstract;
  }

  static String _extractTitle(dynamic title) {
    // Extract the title if it's not null and is a non-empty list
    return title != null && title is List<dynamic> && (title.isNotEmpty)
        ? title.first ?? ''
        : '';
  }

  static DateTime _parseDate(dynamic dateData) {
    if (dateData != null && dateData['date-parts'] != null) {
      var dateParts = dateData['date-parts'][0];
      if (dateParts.length >= 3) {
        return DateTime(dateParts[0], dateParts[1], dateParts[2]);
      }
    }
    return DateTime.now(); // Default to the current date if parsing fails
  }

  // Normalize the license Url to ensure a match
  static String normalizeLicenseUrl(String url) {
    if (url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  @override
  String toString() {
    return 'Item{publisher: $publisher, abstract: $abstract}';
  }
}

class PublicationAuthor {
  final String given;
  final String family;

  PublicationAuthor({
    required this.given,
    required this.family,
  });
  Map<String, dynamic> toJson() {
    return {
      'given': given,
      'family': family,
    };
  }

  factory PublicationAuthor.fromJson(Map<String, dynamic> json) {
    return PublicationAuthor(
      given: json['given'] ?? '',
      family: json['family'] ?? '',
    );
  }
}
