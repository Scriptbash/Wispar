// To parse this JSON data, do
//
//     final crossrefjournals = crossrefjournalsFromJson(jsonString);

import 'dart:convert';

Crossrefjournals crossrefjournalsFromJson(String str) =>
    Crossrefjournals.fromJson(json.decode(str));

String crossrefjournalsToJson(Crossrefjournals data) =>
    json.encode(data.toJson());

class Crossrefjournals {
  String status;
  String messageType;
  String messageVersion;
  Message message;

  Crossrefjournals({
    required this.status,
    required this.messageType,
    required this.messageVersion,
    required this.message,
  });

  factory Crossrefjournals.fromJson(Map<String, dynamic> json) =>
      Crossrefjournals(
        status: json["status"],
        messageType: json["message-type"],
        messageVersion: json["message-version"],
        message: Message.fromJson(json["message"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message-type": messageType,
        "message-version": messageVersion,
        "message": message.toJson(),
      };
}

class Message {
  int itemsPerPage;
  Query query;
  String nextCursor;
  int totalResults;
  List<Item> items;

  Message({
    required this.itemsPerPage,
    required this.query,
    required this.nextCursor,
    required this.totalResults,
    required this.items,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        itemsPerPage: json["items-per-page"],
        query: Query.fromJson(json["query"]),
        nextCursor: json["next-cursor"],
        totalResults: json["total-results"],
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "items-per-page": itemsPerPage,
        "query": query.toJson(),
        "next-cursor": nextCursor,
        "total-results": totalResults,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
      };
}

class Item {
  String publisher;
  String title;
  List<String> issn;
  List<IssnType> issnType;

  Item({
    required this.publisher,
    required this.title,
    required this.issn,
    required this.issnType,
  });

  factory Item.fromJson(Map<String, dynamic> json, [String? queriedISSN]) =>
      Item(
        publisher: json["publisher"] ?? "Unknown",
        title: json["title"] ?? "Untitled",
        issn: (queriedISSN != null && json["ISSN"].contains(queriedISSN))
            ? <String>[queriedISSN]
            : List<String>.from(json["ISSN"]?.map((x) => x) ?? []),
        issnType: List<IssnType>.from(
          (json["issn-type"] ?? []).map((x) => IssnType.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
        "publisher": publisher,
        "title": title,
        "ISSN": List<dynamic>.from(issn.map((x) => x)),
        "issn-type": List<dynamic>.from(issnType.map((x) => x.toJson())),
      };
}

class IssnType {
  String value;
  Type type;

  IssnType({
    required this.value,
    required this.type,
  });

  factory IssnType.fromJson(Map<String, dynamic> json) => IssnType(
        value: json["value"] ?? "",
        type: typeValues.map[json["type"]] ?? Type.ELECTRONIC,
      );

  Map<String, dynamic> toJson() => {
        "value": value,
        "type": typeValues.reverse[type],
      };
}

enum Type { ELECTRONIC, PRINT }

final typeValues =
    EnumValues({"electronic": Type.ELECTRONIC, "print": Type.PRINT});

class Query {
  int startIndex;
  String searchTerms;

  Query({
    required this.startIndex,
    required this.searchTerms,
  });

  factory Query.fromJson(Map<String, dynamic> json) => Query(
        startIndex: json["start-index"] ?? 0,
        searchTerms: json["search-terms"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "start-index": startIndex,
        "search-terms": searchTerms,
      };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
