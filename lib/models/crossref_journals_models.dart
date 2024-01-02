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
  int lastStatusCheckTime;
  Counts counts;
  Breakdowns breakdowns;
  String publisher;
  Map<String, double> coverage;
  String title;
  List<Subject> subjects;
  CoverageType coverageType;
  Map<String, bool> flags;
  List<String> issn;
  List<IssnType> issnType;

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
            .map((k, v) => MapEntry<String, double>(k, v?.toDouble())),
        title: json["title"],
        subjects: List<Subject>.from(
            json["subjects"].map((x) => Subject.fromJson(x))),
        coverageType: CoverageType.fromJson(json["coverage-type"]),
        flags:
            Map.from(json["flags"]).map((k, v) => MapEntry<String, bool>(k, v)),
        issn: List<String>.from(json["ISSN"].map((x) => x)),
        issnType: List<IssnType>.from(
            json["issn-type"].map((x) => IssnType.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "last-status-check-time": lastStatusCheckTime,
        "counts": counts.toJson(),
        "breakdowns": breakdowns.toJson(),
        "publisher": publisher,
        "coverage":
            Map.from(coverage).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "title": title,
        "subjects": List<dynamic>.from(subjects.map((x) => x.toJson())),
        "coverage-type": coverageType.toJson(),
        "flags": Map.from(flags).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "ISSN": List<dynamic>.from(issn.map((x) => x)),
        "issn-type": List<dynamic>.from(issnType.map((x) => x.toJson())),
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
  int currentDois;
  int backfileDois;
  int totalDois;

  Counts({
    required this.currentDois,
    required this.backfileDois,
    required this.totalDois,
  });

  factory Counts.fromJson(Map<String, dynamic> json) => Counts(
        currentDois: json["current-dois"],
        backfileDois: json["backfile-dois"],
        totalDois: json["total-dois"],
      );

  Map<String, dynamic> toJson() => {
        "current-dois": currentDois,
        "backfile-dois": backfileDois,
        "total-dois": totalDois,
      };
}

class CoverageType {
  Map<String, double> all;
  Map<String, double> backfile;
  Map<String, double> current;

  CoverageType({
    required this.all,
    required this.backfile,
    required this.current,
  });

  factory CoverageType.fromJson(Map<String, dynamic> json) => CoverageType(
        all: Map.from(json["all"])
            .map((k, v) => MapEntry<String, double>(k, v?.toDouble())),
        backfile: Map.from(json["backfile"])
            .map((k, v) => MapEntry<String, double>(k, v?.toDouble())),
        current: Map.from(json["current"])
            .map((k, v) => MapEntry<String, double>(k, v?.toDouble())),
      );

  Map<String, dynamic> toJson() => {
        "all": Map.from(all).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "backfile":
            Map.from(backfile).map((k, v) => MapEntry<String, dynamic>(k, v)),
        "current":
            Map.from(current).map((k, v) => MapEntry<String, dynamic>(k, v)),
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
        value: json["value"],
        type: typeValues.map[json["type"]]!,
      );

  Map<String, dynamic> toJson() => {
        "value": value,
        "type": typeValues.reverse[type],
      };
}

enum Type { ELECTRONIC, PRINT }

final typeValues =
    EnumValues({"electronic": Type.ELECTRONIC, "print": Type.PRINT});

class Subject {
  int asjc;
  String name;

  Subject({
    required this.asjc,
    required this.name,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        asjc: json["ASJC"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "ASJC": asjc,
        "name": name,
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

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
