// To parse this JSON data, do
//
//     final crossrefJournals = crossrefJournalsFromJson(jsonString);

import 'dart:convert';

CrossrefJournals crossrefJournalsFromJson(String str) =>
    CrossrefJournals.fromJson(json.decode(str));

String crossrefJournalsToJson(CrossrefJournals data) =>
    json.encode(data.toJson());

class CrossrefJournals {
  String status;
  String messageType;
  String messageVersion;
  Message message;

  CrossrefJournals({
    required this.status,
    required this.messageType,
    required this.messageVersion,
    required this.message,
  });

  factory CrossrefJournals.fromJson(Map<String, dynamic> json) =>
      CrossrefJournals(
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
  int totalResults;
  List<Item> items;

  Message({
    required this.itemsPerPage,
    required this.query,
    required this.totalResults,
    required this.items,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        itemsPerPage: json["items-per-page"],
        query: Query.fromJson(json["query"]),
        totalResults: json["total-results"],
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "items-per-page": itemsPerPage,
        "query": query.toJson(),
        "total-results": totalResults,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
      };
}

class Item {
  int lastStatusCheckTime;
  Counts counts;
  Breakdowns breakdowns;
  String publisher;
  Map<String, int> coverage;
  String title;
  List<String> subjects;
  CoverageType coverageType;
  Map<String, bool> flags;
  List<String> issn;
  IssnType issnType;

  Item({
    required this.lastStatusCheckTime,
    required this.counts,
    required this.breakdowns,
    required this.publisher,
    required this.coverage,
    required this.title,
    required this.subjects,
    required this.coverageType,
    required this.flags,
    required this.issn,
    required this.issnType,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        lastStatusCheckTime: json["last-status-check-time"],
        counts: Counts.fromJson(json["counts"]),
        breakdowns: Breakdowns.fromJson(json["breakdowns"]),
        publisher: json["publisher"],
        coverage: Map.from(json["coverage"])
            .map((k, v) => MapEntry<String, int>(k, v)),
        title: json["title"],
        subjects: List<String>.from(json["subjects"].map((x) => x)),
        coverageType: CoverageType.fromJson(json["coverage-type"]),
        flags:
            Map.from(json["flags"]).map((k, v) => MapEntry<String, bool>(k, v)),
        issn: List<String>.from(json["ISSN"].map((x) => x)),
        issnType: IssnType.fromJson(json["issn-type"]),
      );

  Map<String, dynamic> toJson() => {
        "last-status-check-time": lastStatusCheckTime,
        "counts": counts.toJson(),
        "breakdowns": breakdowns.toJson(),
        "publisher": publisher,
        "coverage":
            Map.from(coverage).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "title": title,
        "subjects": List<dynamic>.from(subjects.map((x) => x)),
        "coverage-type": coverageType.toJson(),
        "flags": Map.from(flags).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "ISSN": List<dynamic>.from(issn.map((x) => x)),
        "issn-type": issnType.toJson(),
      };
}

class Breakdowns {
  List<List<int>> doisByIssuedYear;

  Breakdowns({
    required this.doisByIssuedYear,
  });

  factory Breakdowns.fromJson(Map<String, dynamic> json) => Breakdowns(
        doisByIssuedYear: List<List<int>>.from(json["dois-by-issued-year"]
            .map((x) => List<int>.from(x.map((x) => x)))),
      );

  Map<String, dynamic> toJson() => {
        "dois-by-issued-year": List<dynamic>.from(
            doisByIssuedYear.map((x) => List<dynamic>.from(x.map((x) => x)))),
      };
}

class Counts {
  int totalDois;
  int currentDois;
  int backfileDois;

  Counts({
    required this.totalDois,
    required this.currentDois,
    required this.backfileDois,
  });

  factory Counts.fromJson(Map<String, dynamic> json) => Counts(
        totalDois: json["total-dois"],
        currentDois: json["current-dois"],
        backfileDois: json["backfile-dois"],
      );

  Map<String, dynamic> toJson() => {
        "total-dois": totalDois,
        "current-dois": currentDois,
        "backfile-dois": backfileDois,
      };
}

class CoverageType {
  Map<String, int> all;
  Map<String, int> current;
  Map<String, int> backfile;

  CoverageType({
    required this.all,
    required this.current,
    required this.backfile,
  });

  factory CoverageType.fromJson(Map<String, dynamic> json) => CoverageType(
        all: Map.from(json["all"]).map((k, v) => MapEntry<String, int>(k, v)),
        current: Map.from(json["current"])
            .map((k, v) => MapEntry<String, int>(k, v)),
        backfile: Map.from(json["backfile"])
            .map((k, v) => MapEntry<String, int>(k, v)),
      );

  Map<String, dynamic> toJson() => {
        "all": Map.from(all).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "current":
            Map.from(current).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "backfile":
            Map.from(backfile).map((k, v) => MapEntry<String, dynamic>(k, v)),
      };
}

class IssnType {
  String value;
  String type;

  IssnType({
    required this.value,
    required this.type,
  });

  factory IssnType.fromJson(Map<String, dynamic> json) => IssnType(
        value: json["value"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "value": value,
        "type": type,
      };
}

class Query {
  int startIndex;
  String searchTerms;

  Query({
    required this.startIndex,
    required this.searchTerms,
  });

  factory Query.fromJson(Map<String, dynamic> json) => Query(
        startIndex: json["start-index"],
        searchTerms: json["search-terms"],
      );

  Map<String, dynamic> toJson() => {
        "start-index": startIndex,
        "search-terms": searchTerms,
      };
}
