// To parse this JSON data, do
//
//     final crossrefworks = crossrefworksFromJson(jsonString);

import 'dart:convert';

Crossrefworks crossrefworksFromJson(String str) =>
    Crossrefworks.fromJson(json.decode(str));

String crossrefworksToJson(Crossrefworks data) => json.encode(data.toJson());

class Crossrefworks {
  String status;
  String messageType;
  String messageVersion;
  Message message;

  Crossrefworks({
    required this.status,
    required this.messageType,
    required this.messageVersion,
    required this.message,
  });

  factory Crossrefworks.fromJson(Map<String, dynamic> json) => Crossrefworks(
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
  Facets facets;
  String nextCursor;
  num totalResults;
  List<Item> items;
  num itemsPerPage;
  Query query;

  Message({
    required this.facets,
    required this.nextCursor,
    required this.totalResults,
    required this.items,
    required this.itemsPerPage,
    required this.query,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        facets: Facets.fromJson(json["facets"]),
        nextCursor: json["next-cursor"],
        totalResults: json["total-results"],
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
        itemsPerPage: json["items-per-page"],
        query: Query.fromJson(json["query"]),
      );

  Map<String, dynamic> toJson() => {
        "facets": facets.toJson(),
        "next-cursor": nextCursor,
        "total-results": totalResults,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
        "items-per-page": itemsPerPage,
        "query": query.toJson(),
      };
}

class Facets {
  Facets();

  factory Facets.fromJson(Map<String, dynamic> json) => Facets();

  Map<String, dynamic> toJson() => {};
}

class Item {
  Created indexed;
  num referenceCount;
  String? publisher;
  String? issue;
  List<License>? license;
  ContentDomain contentDomain;
  List<String>? shortContainerTitle;
  Issued? publishedPrint;
  String doi;
  ItemType type;
  Created created;
  String? page;
  Source source;
  num isReferencedByCount;
  List<String> title;
  String prefix;
  String? volume;
  List<Author>? author;
  String? member;
  List<String>? containerTitle;
  List<Link>? link;
  Created deposited;
  num score;
  Resource resource;
  Issued issued;
  num referencesCount;
  JournalIssue? journalIssue;
  List<String>? alternativeId;
  String url;
  List<String>? issn;
  List<NType>? issnType;
  List<Subject>? subject;
  Issued published;
  Issued? publishedOnline;
  String? itemAbstract;
  String? updatePolicy;
  String? editionNumber;
  List<NType>? isbnType;
  List<String>? isbn;
  String? language;

  Item({
    required this.indexed,
    required this.referenceCount,
    this.publisher,
    this.issue,
    this.license,
    required this.contentDomain,
    this.shortContainerTitle,
    this.publishedPrint,
    required this.doi,
    required this.type,
    required this.created,
    this.page,
    required this.source,
    required this.isReferencedByCount,
    required this.title,
    required this.prefix,
    this.volume,
    this.author,
    this.member,
    this.containerTitle,
    this.link,
    required this.deposited,
    required this.score,
    required this.resource,
    required this.issued,
    required this.referencesCount,
    this.journalIssue,
    this.alternativeId,
    required this.url,
    this.issn,
    this.issnType,
    this.subject,
    required this.published,
    this.publishedOnline,
    this.itemAbstract,
    this.updatePolicy,
    this.editionNumber,
    this.isbnType,
    this.isbn,
    this.language,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        indexed: Created.fromJson(json["indexed"]),
        referenceCount: json["reference-count"],
        publisher: json["publisher"],
        issue: json["issue"],
        license: json["license"] == null
            ? []
            : List<License>.from(
                json["license"]!.map((x) => License.fromJson(x))),
        contentDomain: ContentDomain.fromJson(json["content-domain"]),
        shortContainerTitle: json["short-container-title"] == null
            ? []
            : List<String>.from(json["short-container-title"]!.map((x) => x)),
        publishedPrint: json["published-print"] == null
            ? null
            : Issued.fromJson(json["published-print"]),
        doi: json["DOI"],
        type: itemTypeValues.map[json["type"]]!,
        created: Created.fromJson(json["created"]),
        page: json["page"],
        source: sourceValues.map[json["source"]]!,
        isReferencedByCount: json["is-referenced-by-count"],
        title: List<String>.from(json["title"].map((x) => x)),
        prefix: json["prefix"],
        volume: json["volume"],
        author: json["author"] == null
            ? []
            : List<Author>.from(json["author"]!.map((x) => Author.fromJson(x))),
        member: json["member"],
        containerTitle: json["container-title"] == null
            ? []
            : List<String>.from(json["container-title"]!.map((x) => x)),
        link: json["link"] == null
            ? []
            : List<Link>.from(json["link"]!.map((x) => Link.fromJson(x))),
        deposited: Created.fromJson(json["deposited"]),
        score: json["score"],
        resource: Resource.fromJson(json["resource"]),
        issued: Issued.fromJson(json["issued"]),
        referencesCount: json["references-count"],
        journalIssue: json["journal-issue"] == null
            ? null
            : JournalIssue.fromJson(json["journal-issue"]),
        alternativeId: json["alternative-id"] == null
            ? []
            : List<String>.from(json["alternative-id"]!.map((x) => x)),
        url: json["URL"],
        issn: json["ISSN"] == null
            ? []
            : List<String>.from(json["ISSN"]!.map((x) => x)),
        issnType: json["issn-type"] == null
            ? []
            : List<NType>.from(
                json["issn-type"]!.map((x) => NType.fromJson(x))),
        subject: json["subject"] == null
            ? []
            : List<Subject>.from(
                json["subject"]!.map((x) => subjectValues.map[x]!)),
        published: Issued.fromJson(json["published"]),
        publishedOnline: json["published-online"] == null
            ? null
            : Issued.fromJson(json["published-online"]),
        itemAbstract: json["abstract"],
        updatePolicy: json["update-policy"],
        editionNumber: json["edition-number"],
        isbnType: json["isbn-type"] == null
            ? []
            : List<NType>.from(
                json["isbn-type"]!.map((x) => NType.fromJson(x))),
        isbn: json["ISBN"] == null
            ? []
            : List<String>.from(json["ISBN"]!.map((x) => x)),
        language: json["language"],
      );

  Map<String, dynamic> toJson() => {
        "indexed": indexed.toJson(),
        "reference-count": referenceCount,
        "publisher": publisher,
        "issue": issue,
        "license": license == null
            ? []
            : List<dynamic>.from(license!.map((x) => x.toJson())),
        "content-domain": contentDomain.toJson(),
        "short-container-title": shortContainerTitle == null
            ? []
            : List<dynamic>.from(shortContainerTitle!.map((x) => x)),
        "published-print": publishedPrint?.toJson(),
        "DOI": doi,
        "type": itemTypeValues.reverse[type],
        "created": created.toJson(),
        "page": page,
        "source": sourceValues.reverse[source],
        "is-referenced-by-count": isReferencedByCount,
        "title": List<dynamic>.from(title.map((x) => x)),
        "prefix": prefix,
        "volume": volume,
        "author": author == null
            ? []
            : List<dynamic>.from(author!.map((x) => x.toJson())),
        "member": member,
        "container-title": containerTitle == null
            ? []
            : List<dynamic>.from(containerTitle!.map((x) => x)),
        "link": link == null
            ? []
            : List<dynamic>.from(link!.map((x) => x.toJson())),
        "deposited": deposited.toJson(),
        "score": score,
        "resource": resource.toJson(),
        "issued": issued.toJson(),
        "references-count": referencesCount,
        "journal-issue": journalIssue?.toJson(),
        "alternative-id": alternativeId == null
            ? []
            : List<dynamic>.from(alternativeId!.map((x) => x)),
        "URL": url,
        "ISSN": issn == null ? [] : List<dynamic>.from(issn!.map((x) => x)),
        "issn-type": issnType == null
            ? []
            : List<dynamic>.from(issnType!.map((x) => x.toJson())),
        "subject": subject == null
            ? []
            : List<dynamic>.from(subject!.map((x) => subjectValues.reverse[x])),
        "published": published.toJson(),
        "published-online": publishedOnline?.toJson(),
        "abstract": itemAbstract,
        "update-policy": updatePolicy,
        "edition-number": editionNumber,
        "isbn-type": isbnType == null
            ? []
            : List<dynamic>.from(isbnType!.map((x) => x.toJson())),
        "ISBN": isbn == null ? [] : List<dynamic>.from(isbn!.map((x) => x)),
        "language": language,
      };
}

class Author {
  String? given;
  String? family;
  Sequence sequence;
  List<dynamic> affiliation;
  String? name;

  Author({
    this.given,
    this.family,
    required this.sequence,
    required this.affiliation,
    this.name,
  });

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        given: json["given"],
        family: json["family"],
        sequence: sequenceValues.map[json["sequence"]]!,
        affiliation: List<dynamic>.from(json["affiliation"].map((x) => x)),
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "given": given,
        "family": family,
        "sequence": sequenceValues.reverse[sequence],
        "affiliation": List<dynamic>.from(affiliation.map((x) => x)),
        "name": name,
      };
}

enum Sequence { ADDITIONAL, FIRST }

final sequenceValues =
    EnumValues({"additional": Sequence.ADDITIONAL, "first": Sequence.FIRST});

class ContentDomain {
  List<Domain> domain;
  bool crossmarkRestriction;

  ContentDomain({
    required this.domain,
    required this.crossmarkRestriction,
  });

  factory ContentDomain.fromJson(Map<String, dynamic> json) => ContentDomain(
        domain:
            List<Domain>.from(json["domain"].map((x) => domainValues.map[x]!)),
        crossmarkRestriction: json["crossmark-restriction"],
      );

  Map<String, dynamic> toJson() => {
        "domain":
            List<dynamic>.from(domain.map((x) => domainValues.reverse[x])),
        "crossmark-restriction": crossmarkRestriction,
      };
}

enum Domain { WWW_NISCPUB_COM }

final domainValues = EnumValues({"www.niscpub.com": Domain.WWW_NISCPUB_COM});

class Created {
  List<List<num>> dateParts;
  DateTime dateTime;
  num timestamp;

  Created({
    required this.dateParts,
    required this.dateTime,
    required this.timestamp,
  });

  factory Created.fromJson(Map<String, dynamic> json) => Created(
        dateParts: List<List<num>>.from(
            json["date-parts"].map((x) => List<num>.from(x.map((x) => x)))),
        dateTime: DateTime.parse(json["date-time"]),
        timestamp: json["timestamp"],
      );

  Map<String, dynamic> toJson() => {
        "date-parts": List<dynamic>.from(
            dateParts.map((x) => List<dynamic>.from(x.map((x) => x)))),
        "date-time": dateTime.toIso8601String(),
        "timestamp": timestamp,
      };
}

class NType {
  String value;
  IsbnTypeType type;

  NType({
    required this.value,
    required this.type,
  });

  factory NType.fromJson(Map<String, dynamic> json) => NType(
        value: json["value"],
        type: isbnTypeTypeValues.map[json["type"]]!,
      );

  Map<String, dynamic> toJson() => {
        "value": value,
        "type": isbnTypeTypeValues.reverse[type],
      };
}

enum IsbnTypeType { ELECTRONIC, PRINT }

final isbnTypeTypeValues = EnumValues(
    {"electronic": IsbnTypeType.ELECTRONIC, "print": IsbnTypeType.PRINT});

class Issued {
  List<List<num>> dateParts;

  Issued({
    required this.dateParts,
  });

  factory Issued.fromJson(Map<String, dynamic> json) => Issued(
        dateParts: List<List<num>>.from(
            json["date-parts"].map((x) => List<num>.from(x.map((x) => x)))),
      );

  Map<String, dynamic> toJson() => {
        "date-parts": List<dynamic>.from(
            dateParts.map((x) => List<dynamic>.from(x.map((x) => x)))),
      };
}

class JournalIssue {
  String issue;
  Issued? publishedPrint;
  Issued? publishedOnline;

  JournalIssue({
    required this.issue,
    this.publishedPrint,
    this.publishedOnline,
  });

  factory JournalIssue.fromJson(Map<String, dynamic> json) => JournalIssue(
        issue: json["issue"],
        publishedPrint: json["published-print"] == null
            ? null
            : Issued.fromJson(json["published-print"]),
        publishedOnline: json["published-online"] == null
            ? null
            : Issued.fromJson(json["published-online"]),
      );

  Map<String, dynamic> toJson() => {
        "issue": issue,
        "published-print": publishedPrint?.toJson(),
        "published-online": publishedOnline?.toJson(),
      };
}

class License {
  Created start;
  ContentVersion contentVersion;
  num delayInDays;
  String url;

  License({
    required this.start,
    required this.contentVersion,
    required this.delayInDays,
    required this.url,
  });

  factory License.fromJson(Map<String, dynamic> json) => License(
        start: Created.fromJson(json["start"]),
        contentVersion: contentVersionValues.map[json["content-version"]]!,
        delayInDays: json["delay-in-days"],
        url: json["URL"],
      );

  Map<String, dynamic> toJson() => {
        "start": start.toJson(),
        "content-version": contentVersionValues.reverse[contentVersion],
        "delay-in-days": delayInDays,
        "URL": url,
      };
}

enum ContentVersion { TDM, VOR }

final contentVersionValues =
    EnumValues({"tdm": ContentVersion.TDM, "vor": ContentVersion.VOR});

class Link {
  String url;
  ContentType contentType;
  ContentVersion contentVersion;
  IntendedApplication intendedApplication;

  Link({
    required this.url,
    required this.contentType,
    required this.contentVersion,
    required this.intendedApplication,
  });

  factory Link.fromJson(Map<String, dynamic> json) => Link(
        url: json["URL"],
        contentType: contentTypeValues.map[json["content-type"]]!,
        contentVersion: contentVersionValues.map[json["content-version"]]!,
        intendedApplication:
            intendedApplicationValues.map[json["intended-application"]]!,
      );

  Map<String, dynamic> toJson() => {
        "URL": url,
        "content-type": contentTypeValues.reverse[contentType],
        "content-version": contentVersionValues.reverse[contentVersion],
        "intended-application":
            intendedApplicationValues.reverse[intendedApplication],
      };
}

enum ContentType { APPLICATION_PDF, TEXT_PLAIN, TEXT_XML, UNSPECIFIED }

final contentTypeValues = EnumValues({
  "application/pdf": ContentType.APPLICATION_PDF,
  "text/plain": ContentType.TEXT_PLAIN,
  "text/xml": ContentType.TEXT_XML,
  "unspecified": ContentType.UNSPECIFIED
});

enum IntendedApplication { SIMILARITY_CHECKING, TEXT_MINING }

final intendedApplicationValues = EnumValues({
  "similarity-checking": IntendedApplication.SIMILARITY_CHECKING,
  "text-mining": IntendedApplication.TEXT_MINING
});

class Resource {
  Primary primary;

  Resource({
    required this.primary,
  });

  factory Resource.fromJson(Map<String, dynamic> json) => Resource(
        primary: Primary.fromJson(json["primary"]),
      );

  Map<String, dynamic> toJson() => {
        "primary": primary.toJson(),
      };
}

class Primary {
  String url;

  Primary({
    required this.url,
  });

  factory Primary.fromJson(Map<String, dynamic> json) => Primary(
        url: json["URL"],
      );

  Map<String, dynamic> toJson() => {
        "URL": url,
      };
}

enum Source { CROSSREF }

final sourceValues = EnumValues({"Crossref": Source.CROSSREF});

enum Subject {
  CLINICAL_PSYCHOLOGY,
  FAMILY_PRACTICE,
  GENERAL_ARTS_AND_HUMANITIES,
  GENERAL_MEDICINE,
  GENERAL_SOCIAL_SCIENCES,
  MEDICINE_MISCELLANEOUS,
  PSYCHIATRY_AND_MENTAL_HEALTH
}

final subjectValues = EnumValues({
  "Clinical Psychology": Subject.CLINICAL_PSYCHOLOGY,
  "Family Practice": Subject.FAMILY_PRACTICE,
  "General Arts and Humanities": Subject.GENERAL_ARTS_AND_HUMANITIES,
  "General Medicine": Subject.GENERAL_MEDICINE,
  "General Social Sciences": Subject.GENERAL_SOCIAL_SCIENCES,
  "Medicine (miscellaneous)": Subject.MEDICINE_MISCELLANEOUS,
  "Psychiatry and Mental health": Subject.PSYCHIATRY_AND_MENTAL_HEALTH
});

enum ItemType { EDITED_BOOK, JOURNAL_ARTICLE }

final itemTypeValues = EnumValues({
  "edited-book": ItemType.EDITED_BOOK,
  "journal-article": ItemType.JOURNAL_ARTICLE
});

class Query {
  num startIndex;
  dynamic searchTerms;

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
