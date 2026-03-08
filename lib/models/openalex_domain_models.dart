class OpenAlexDomain {
  final String id;
  final String shortId;
  final String displayName;
  final List<OpenAlexField> fields;

  OpenAlexDomain({
    required this.id,
    required this.shortId,
    required this.displayName,
    required this.fields,
  });

  factory OpenAlexDomain.fromJson(Map<String, dynamic> json) {
    final fullId = json['id'] ?? '';

    return OpenAlexDomain(
      id: fullId,
      shortId: fullId.split('/').last,
      displayName: json['display_name'] ?? '',
      fields: (json['fields'] as List?)
              ?.map((f) => OpenAlexField.fromJson(f))
              .toList() ??
          [],
    );
  }
}

class OpenAlexField {
  final String id;
  final String shortId;
  final String displayName;

  OpenAlexField({
    required this.id,
    required this.shortId,
    required this.displayName,
  });

  factory OpenAlexField.fromJson(Map<String, dynamic> json) {
    final fullId = json['id'] ?? '';

    return OpenAlexField(
      id: fullId,
      shortId: fullId.split('/').last,
      displayName: json['display_name'] ?? '',
    );
  }
}

class OpenAlexSubfield {
  final String id;
  final String shortId;
  final String displayName;
  final List<OpenAlexTopic> topics;

  OpenAlexSubfield({
    required this.id,
    required this.shortId,
    required this.displayName,
    required this.topics,
  });

  factory OpenAlexSubfield.fromJson(Map<String, dynamic> json) {
    final fullId = json['id'] ?? '';

    return OpenAlexSubfield(
      id: fullId,
      shortId: fullId.split('/').last,
      displayName: json['display_name'] ?? '',
      topics: (json['topics'] as List?)
              ?.map((t) => OpenAlexTopic.fromJson(t))
              .toList() ??
          [],
    );
  }
}

class OpenAlexTopic {
  final String id;
  final String displayName;

  OpenAlexTopic({
    required this.id,
    required this.displayName,
  });

  factory OpenAlexTopic.fromJson(Map<String, dynamic> json) {
    return OpenAlexTopic(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? '',
    );
  }
}

class TopicJournalResult {
  final String title;
  final String publisher;
  final List<String> issn;

  TopicJournalResult({
    required this.title,
    required this.publisher,
    required this.issn,
  });

  factory TopicJournalResult.fromJson(Map<String, dynamic> json) {
    return TopicJournalResult(
      title: json['display_name'] ?? '',
      publisher: json['host_organization_name'] ?? '',
      issn: (json['issn'] as List?)?.cast<String>() ?? [],
    );
  }
}
