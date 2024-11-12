class Journal {
  final int? id;
  final String issn;
  final String title;
  final String publisher;
  final String subjects;
  final String? dateFollowed;
  final String? lastUpdated;

  Journal({
    this.id,
    required this.issn,
    required this.title,
    required this.publisher,
    required this.subjects,
    this.dateFollowed,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'issn': issn,
      'title': title,
      'publisher': publisher,
      'subjects': subjects,
      'dateFollowed': DateTime.now().toIso8601String().substring(0, 10),
      'lastUpdated': lastUpdated,
    };
  }
}
