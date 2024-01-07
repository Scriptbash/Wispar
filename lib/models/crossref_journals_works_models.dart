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
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    List<PublicationAuthor> authors = [];
    if (json['author'] != null && json['author'] is List) {
      authors = (json['author'] as List<dynamic>)
          .map((authorJson) => PublicationAuthor.fromJson(authorJson))
          .toList();
    }
    return Item(
      publisher: json['publisher'] ?? '',
      abstract: _cleanAbstract(json['abstract'] ?? ''),
      title: _extractTitle(json['title']),
      publishedDate: _parseDate(json['created']),
      journalTitle: (json['container-title'] as List<dynamic>).isNotEmpty
          ? (json['container-title'] as List<dynamic>).first ?? ''
          : '',
      doi: json['DOI'] ?? '',
      authors: authors,
      url: json['URL'] ?? '',
      primaryUrl: json['resource']['primary']['URL'] ?? '',
    );
  }

  static String _cleanAbstract(String rawAbstract) {
    return rawAbstract
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\bAbstract\b'),
            '') // Remove the word "Abstract" in between the HTML tags
        .trim();
  }

  static String _extractTitle(dynamic title) {
    // Extract the title if it's not null and is a non-empty list
    return (title != null &&
            title is List<dynamic> &&
            (title as List<dynamic>).isNotEmpty)
        ? (title as List<dynamic>).first ?? ''
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

  factory PublicationAuthor.fromJson(Map<String, dynamic> json) {
    return PublicationAuthor(
      given: json['given'] ?? '',
      family: json['family'] ?? '',
    );
  }
}
