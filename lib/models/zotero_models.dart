class ZoteroCollection {
  final String key;
  final String name;
  final String? parentKey;
  final bool isGroupLibrary;
  final String? libraryId;

  ZoteroCollection(
      {required this.key,
      required this.name,
      this.parentKey,
      required this.isGroupLibrary,
      this.libraryId});

  factory ZoteroCollection.fromJson(
    Map<String, dynamic> json, {
    bool isGroupLibrary = false,
    String? libraryId,
  }) {
    if (json.containsKey('name') && json.containsKey('key')) {
      return ZoteroCollection(
        key: json['key'] ?? '',
        name: json['name'] ?? '',
        parentKey: json['parentKey'] as String?,
        isGroupLibrary: json['isGroupLibrary'] ?? false,
        libraryId: json['libraryId'] as String?,
      );
    }

    final data = json['data'] as Map<String, dynamic>?;

    return ZoteroCollection(
      key: json['key'] ?? '',
      name: data?['name'] ?? '',
      parentKey: data != null && data['parentCollection'] is String
          ? data['parentCollection'] as String
          : null,
      isGroupLibrary: isGroupLibrary,
      libraryId: libraryId,
    );
  }
  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'parentKey': parentKey,
        'isGroupLibrary': isGroupLibrary,
        'libraryId': libraryId,
      };
}

class ZoteroItem {
  final String key;
  final String name;

  ZoteroItem({
    required this.key,
    required this.name,
  });
}
