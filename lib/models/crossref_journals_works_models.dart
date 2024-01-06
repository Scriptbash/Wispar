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

  Item({
    required this.publisher,
    required this.abstract,
    required this.title,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      publisher: json['publisher'] ?? '',
      abstract: _cleanAbstract(json['abstract'] ?? ''),
      title: _extractTitle(json['title']),
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

  @override
  String toString() {
    return 'Item{publisher: $publisher, abstract: $abstract}';
  }
}
