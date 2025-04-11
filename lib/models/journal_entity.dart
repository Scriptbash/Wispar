class Journal {
  final int? id;
  final List<String> issn;
  final String title;
  final String publisher;
  final String? dateFollowed;
  final String? lastUpdated;

  Journal({
    this.id,
    required this.issn,
    required this.title,
    required this.publisher,
    this.dateFollowed,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'publisher': publisher,
      'dateFollowed': DateTime.now().toIso8601String().substring(0, 10),
      'lastUpdated': lastUpdated,
    };
  }
}
