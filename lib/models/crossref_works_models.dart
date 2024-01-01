// To parse this JSON data, do
//
//     final crossrefWorks = crossrefWorksFromJson(jsonString);

import 'dart:convert';

CrossrefWorks crossrefWorksFromJson(String str) =>
    CrossrefWorks.fromJson(json.decode(str));

String crossrefWorksToJson(CrossrefWorks data) => json.encode(data.toJson());

class CrossrefWorks {
  String status;
  String messageType;
  String messageVersion;
  Message message;

  CrossrefWorks({
    required this.status,
    required this.messageType,
    required this.messageVersion,
    required this.message,
  });

  factory CrossrefWorks.fromJson(Map<String, dynamic> json) => CrossrefWorks(
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
  int totalResults;
  List<Item> items;
  int itemsPerPage;
  Query query;

  Message({
    required this.facets,
    required this.totalResults,
    required this.items,
    required this.itemsPerPage,
    required this.query,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        facets: Facets.fromJson(json["facets"]),
        totalResults: json["total-results"],
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
        itemsPerPage: json["items-per-page"],
        query: Query.fromJson(json["query"]),
      );

  Map<String, dynamic> toJson() => {
        "facets": facets.toJson(),
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
  int referenceCount;
  String publisher;
  String issue;
  List<License> license;
  ContentDomain contentDomain;
  List<String> shortContainerTitle;
  String itemAbstract;
  String doi;
  String type;
  Created created;
  String page;
  String source;
  int isReferencedByCount;
  List<String> title;
  String prefix;
  String volume;
  List<Author> author;
  String member;
  Issued publishedOnline;
  List<String> containerTitle;
  String language;
  List<Link> link;
  Created deposited;
  double score;
  Resource resource;
  Issued issued;
  int referencesCount;
  JournalIssue journalIssue;
  List<String> alternativeId;
  String url;
  List<String> issn;
  List<IssnType> issnType;
  List<String> subject;
  Issued published;

  Item({
    required this.indexed,
    required this.referenceCount,
    required this.publisher,
    required this.issue,
    required this.license,
    required this.contentDomain,
    required this.shortContainerTitle,
    required this.itemAbstract,
    required this.doi,
    required this.type,
    required this.created,
    required this.page,
    required this.source,
    required this.isReferencedByCount,
    required this.title,
    required this.prefix,
    required this.volume,
    required this.author,
    required this.member,
    required this.publishedOnline,
    required this.containerTitle,
    required this.language,
    required this.link,
    required this.deposited,
    required this.score,
    required this.resource,
    required this.issued,
    required this.referencesCount,
    required this.journalIssue,
    required this.alternativeId,
    required this.url,
    required this.issn,
    required this.issnType,
    required this.subject,
    required this.published,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        indexed: Created.fromJson(json["indexed"]),
        referenceCount: json["reference-count"],
        publisher: json["publisher"],
        issue: json["issue"],
        license:
            List<License>.from(json["license"].map((x) => License.fromJson(x))),
        contentDomain: ContentDomain.fromJson(json["content-domain"]),
        shortContainerTitle:
            List<String>.from(json["short-container-title"].map((x) => x)),
        itemAbstract: json["abstract"],
        doi: json["DOI"],
        type: json["type"],
        created: Created.fromJson(json["created"]),
        page: json["page"],
        source: json["source"],
        isReferencedByCount: json["is-referenced-by-count"],
        title: List<String>.from(json["title"].map((x) => x)),
        prefix: json["prefix"],
        volume: json["volume"],
        author:
            List<Author>.from(json["author"].map((x) => Author.fromJson(x))),
        member: json["member"],
        publishedOnline: Issued.fromJson(json["published-online"]),
        containerTitle:
            List<String>.from(json["container-title"].map((x) => x)),
        language: json["language"],
        link: List<Link>.from(json["link"].map((x) => Link.fromJson(x))),
        deposited: Created.fromJson(json["deposited"]),
        score: json["score"]?.toDouble(),
        resource: Resource.fromJson(json["resource"]),
        issued: Issued.fromJson(json["issued"]),
        referencesCount: json["references-count"],
        journalIssue: JournalIssue.fromJson(json["journal-issue"]),
        alternativeId: List<String>.from(json["alternative-id"].map((x) => x)),
        url: json["URL"],
        issn: List<String>.from(json["ISSN"].map((x) => x)),
        issnType: List<IssnType>.from(
            json["issn-type"].map((x) => IssnType.fromJson(x))),
        subject: List<String>.from(json["subject"].map((x) => x)),
        published: Issued.fromJson(json["published"]),
      );

  Map<String, dynamic> toJson() => {
        "indexed": indexed.toJson(),
        "reference-count": referenceCount,
        "publisher": publisher,
        "issue": issue,
        "license": List<dynamic>.from(license.map((x) => x.toJson())),
        "content-domain": contentDomain.toJson(),
        "short-container-title":
            List<dynamic>.from(shortContainerTitle.map((x) => x)),
        "abstract": itemAbstract,
        "DOI": doi,
        "type": type,
        "created": created.toJson(),
        "page": page,
        "source": source,
        "is-referenced-by-count": isReferencedByCount,
        "title": List<dynamic>.from(title.map((x) => x)),
        "prefix": prefix,
        "volume": volume,
        "author": List<dynamic>.from(author.map((x) => x.toJson())),
        "member": member,
        "published-online": publishedOnline.toJson(),
        "container-title": List<dynamic>.from(containerTitle.map((x) => x)),
        "language": language,
        "link": List<dynamic>.from(link.map((x) => x.toJson())),
        "deposited": deposited.toJson(),
        "score": score,
        "resource": resource.toJson(),
        "issued": issued.toJson(),
        "references-count": referencesCount,
        "journal-issue": journalIssue.toJson(),
        "alternative-id": List<dynamic>.from(alternativeId.map((x) => x)),
        "URL": url,
        "ISSN": List<dynamic>.from(issn.map((x) => x)),
        "issn-type": List<dynamic>.from(issnType.map((x) => x.toJson())),
        "subject": List<dynamic>.from(subject.map((x) => x)),
        "published": published.toJson(),
      };
}

class Author {
  String name;
  String sequence;
  List<dynamic> affiliation;

  Author({
    required this.name,
    required this.sequence,
    required this.affiliation,
  });

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        name: json["name"],
        sequence: json["sequence"],
        affiliation: List<dynamic>.from(json["affiliation"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "sequence": sequence,
        "affiliation": List<dynamic>.from(affiliation.map((x) => x)),
      };
}

class ContentDomain {
  List<dynamic> domain;
  bool crossmarkRestriction;

  ContentDomain({
    required this.domain,
    required this.crossmarkRestriction,
  });

  factory ContentDomain.fromJson(Map<String, dynamic> json) => ContentDomain(
        domain: List<dynamic>.from(json["domain"].map((x) => x)),
        crossmarkRestriction: json["crossmark-restriction"],
      );

  Map<String, dynamic> toJson() => {
        "domain": List<dynamic>.from(domain.map((x) => x)),
        "crossmark-restriction": crossmarkRestriction,
      };
}

class Created {
  List<List<int>> dateParts;
  DateTime dateTime;
  int timestamp;

  Created({
    required this.dateParts,
    required this.dateTime,
    required this.timestamp,
  });

  factory Created.fromJson(Map<String, dynamic> json) => Created(
        dateParts: List<List<int>>.from(
            json["date-parts"].map((x) => List<int>.from(x.map((x) => x)))),
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

class Issued {
  List<List<int>> dateParts;

  Issued({
    required this.dateParts,
  });

  factory Issued.fromJson(Map<String, dynamic> json) => Issued(
        dateParts: List<List<int>>.from(
            json["date-parts"].map((x) => List<int>.from(x.map((x) => x)))),
      );

  Map<String, dynamic> toJson() => {
        "date-parts": List<dynamic>.from(
            dateParts.map((x) => List<dynamic>.from(x.map((x) => x)))),
      };
}

class JournalIssue {
  String issue;
  Issued publishedOnline;

  JournalIssue({
    required this.issue,
    required this.publishedOnline,
  });

  factory JournalIssue.fromJson(Map<String, dynamic> json) => JournalIssue(
        issue: json["issue"],
        publishedOnline: Issued.fromJson(json["published-online"]),
      );

  Map<String, dynamic> toJson() => {
        "issue": issue,
        "published-online": publishedOnline.toJson(),
      };
}

class License {
  Created start;
  String contentVersion;
  int delayInDays;
  String url;

  License({
    required this.start,
    required this.contentVersion,
    required this.delayInDays,
    required this.url,
  });

  factory License.fromJson(Map<String, dynamic> json) => License(
        start: Created.fromJson(json["start"]),
        contentVersion: json["content-version"],
        delayInDays: json["delay-in-days"],
        url: json["URL"],
      );

  Map<String, dynamic> toJson() => {
        "start": start.toJson(),
        "content-version": contentVersion,
        "delay-in-days": delayInDays,
        "URL": url,
      };
}

class Link {
  String url;
  String contentType;
  String contentVersion;
  String intendedApplication;

  Link({
    required this.url,
    required this.contentType,
    required this.contentVersion,
    required this.intendedApplication,
  });

  factory Link.fromJson(Map<String, dynamic> json) => Link(
        url: json["URL"],
        contentType: json["content-type"],
        contentVersion: json["content-version"],
        intendedApplication: json["intended-application"],
      );

  Map<String, dynamic> toJson() => {
        "URL": url,
        "content-type": contentType,
        "content-version": contentVersion,
        "intended-application": intendedApplication,
      };
}

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
