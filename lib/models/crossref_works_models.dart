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
  int itemsPerPage;
  Query query;
  int totalResults;
  String nextCursor;
  List<Item> items;

  Message({
    required this.itemsPerPage,
    required this.query,
    required this.totalResults,
    required this.nextCursor,
    required this.items,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        itemsPerPage: json["items-per-page"],
        query: Query.fromJson(json["query"]),
        totalResults: json["total-results"],
        nextCursor: json["next-cursor"],
        items: List<Item>.from(json["items"].map((x) => Item.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "items-per-page": itemsPerPage,
        "query": query.toJson(),
        "total-results": totalResults,
        "next-cursor": nextCursor,
        "items": List<dynamic>.from(items.map((x) => x.toJson())),
      };
}

class Item {
  Institution institution;
  Created indexed;
  Accepted posted;
  String publisherLocation;
  List<UpdateTo> updateTo;
  List<StandardsBody> standardsBody;
  String editionNumber;
  List<String> groupTitle;
  int referenceCount;
  String publisher;
  String issue;
  List<NType> isbnType;
  List<License> license;
  List<Funder> funder;
  ContentDomain contentDomain;
  List<Author> chair;
  String shortContainerTitle;
  Accepted accepted;
  Accepted contentUpdated;
  Accepted publishedPrint;
  String itemAbstract;
  String doi;
  String type;
  Created created;
  Accepted approved;
  String page;
  String updatePolicy;
  String source;
  int isReferencedByCount;
  List<String> title;
  String prefix;
  String volume;
  List<ClinicalTrialNumber> clinicalTrialNumber;
  List<Author> author;
  String member;
  Accepted contentCreated;
  Accepted publishedOnline;
  Reference reference;
  List<String> containerTitle;
  Review review;
  List<String> originalTitle;
  String language;
  List<Link> link;
  Created deposited;
  int score;
  String degree;
  List<String> subtitle;
  List<Author> translator;
  FreeToRead freeToRead;
  List<Author> editor;
  String componentNumber;
  List<String> shortTitle;
  Accepted issued;
  List<String> isbn;
  int referencesCount;
  String partNumber;
  JournalIssue journalIssue;
  List<String> alternativeId;
  String url;
  List<String> archive;
  Relation relation;
  List<String> issn;
  List<NType> issnType;
  List<String> subject;
  Accepted publishedOther;
  Accepted published;
  List<Assertion> assertion;
  String subtype;
  String articleNumber;

  Item({
    required this.institution,
    required this.indexed,
    required this.posted,
    required this.publisherLocation,
    required this.updateTo,
    required this.standardsBody,
    required this.editionNumber,
    required this.groupTitle,
    required this.referenceCount,
    required this.publisher,
    required this.issue,
    required this.isbnType,
    required this.license,
    required this.funder,
    required this.contentDomain,
    required this.chair,
    required this.shortContainerTitle,
    required this.accepted,
    required this.contentUpdated,
    required this.publishedPrint,
    required this.itemAbstract,
    required this.doi,
    required this.type,
    required this.created,
    required this.approved,
    required this.page,
    required this.updatePolicy,
    required this.source,
    required this.isReferencedByCount,
    required this.title,
    required this.prefix,
    required this.volume,
    required this.clinicalTrialNumber,
    required this.author,
    required this.member,
    required this.contentCreated,
    required this.publishedOnline,
    required this.reference,
    required this.containerTitle,
    required this.review,
    required this.originalTitle,
    required this.language,
    required this.link,
    required this.deposited,
    required this.score,
    required this.degree,
    required this.subtitle,
    required this.translator,
    required this.freeToRead,
    required this.editor,
    required this.componentNumber,
    required this.shortTitle,
    required this.issued,
    required this.isbn,
    required this.referencesCount,
    required this.partNumber,
    required this.journalIssue,
    required this.alternativeId,
    required this.url,
    required this.archive,
    required this.relation,
    required this.issn,
    required this.issnType,
    required this.subject,
    required this.publishedOther,
    required this.published,
    required this.assertion,
    required this.subtype,
    required this.articleNumber,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        institution: Institution.fromJson(json["institution"]),
        indexed: Created.fromJson(json["indexed"]),
        posted: Accepted.fromJson(json["posted"]),
        publisherLocation: json["publisher-location"],
        updateTo: List<UpdateTo>.from(
            json["update-to"].map((x) => UpdateTo.fromJson(x))),
        standardsBody: List<StandardsBody>.from(
            json["standards-body"].map((x) => StandardsBody.fromJson(x))),
        editionNumber: json["edition-number"],
        groupTitle: List<String>.from(json["group-title"].map((x) => x)),
        referenceCount: json["reference-count"],
        publisher: json["publisher"],
        issue: json["issue"],
        isbnType:
            List<NType>.from(json["isbn-type"].map((x) => NType.fromJson(x))),
        license:
            List<License>.from(json["license"].map((x) => License.fromJson(x))),
        funder:
            List<Funder>.from(json["funder"].map((x) => Funder.fromJson(x))),
        contentDomain: ContentDomain.fromJson(json["content-domain"]),
        chair: List<Author>.from(json["chair"].map((x) => Author.fromJson(x))),
        shortContainerTitle: json["short-container-title"],
        accepted: Accepted.fromJson(json["accepted"]),
        contentUpdated: Accepted.fromJson(json["content-updated"]),
        publishedPrint: Accepted.fromJson(json["published-print"]),
        itemAbstract: json["abstract"],
        doi: json["DOI"],
        type: json["type"],
        created: Created.fromJson(json["created"]),
        approved: Accepted.fromJson(json["approved"]),
        page: json["page"],
        updatePolicy: json["update-policy"],
        source: json["source"],
        isReferencedByCount: json["is-referenced-by-count"],
        title: List<String>.from(json["title"].map((x) => x)),
        prefix: json["prefix"],
        volume: json["volume"],
        clinicalTrialNumber: List<ClinicalTrialNumber>.from(
            json["clinical-trial-number"]
                .map((x) => ClinicalTrialNumber.fromJson(x))),
        author:
            List<Author>.from(json["author"].map((x) => Author.fromJson(x))),
        member: json["member"],
        contentCreated: Accepted.fromJson(json["content-created"]),
        publishedOnline: Accepted.fromJson(json["published-online"]),
        reference: Reference.fromJson(json["reference"]),
        containerTitle:
            List<String>.from(json["container-title"].map((x) => x)),
        review: Review.fromJson(json["review"]),
        originalTitle: List<String>.from(json["original-title"].map((x) => x)),
        language: json["language"],
        link: List<Link>.from(json["link"].map((x) => Link.fromJson(x))),
        deposited: Created.fromJson(json["deposited"]),
        score: json["score"],
        degree: json["degree"],
        subtitle: List<String>.from(json["subtitle"].map((x) => x)),
        translator: List<Author>.from(
            json["translator"].map((x) => Author.fromJson(x))),
        freeToRead: FreeToRead.fromJson(json["free-to-read"]),
        editor:
            List<Author>.from(json["editor"].map((x) => Author.fromJson(x))),
        componentNumber: json["component-number"],
        shortTitle: List<String>.from(json["short-title"].map((x) => x)),
        issued: Accepted.fromJson(json["issued"]),
        isbn: List<String>.from(json["ISBN"].map((x) => x)),
        referencesCount: json["references-count"],
        partNumber: json["part-number"],
        journalIssue: JournalIssue.fromJson(json["journal-issue"]),
        alternativeId: List<String>.from(json["alternative-id"].map((x) => x)),
        url: json["URL"],
        archive: List<String>.from(json["archive"].map((x) => x)),
        relation: Relation.fromJson(json["relation"]),
        issn: List<String>.from(json["ISSN"].map((x) => x)),
        issnType:
            List<NType>.from(json["issn-type"].map((x) => NType.fromJson(x))),
        subject: List<String>.from(json["subject"].map((x) => x)),
        publishedOther: Accepted.fromJson(json["published-other"]),
        published: Accepted.fromJson(json["published"]),
        assertion: List<Assertion>.from(
            json["assertion"].map((x) => Assertion.fromJson(x))),
        subtype: json["subtype"],
        articleNumber: json["article-number"],
      );

  Map<String, dynamic> toJson() => {
        "institution": institution.toJson(),
        "indexed": indexed.toJson(),
        "posted": posted.toJson(),
        "publisher-location": publisherLocation,
        "update-to": List<dynamic>.from(updateTo.map((x) => x.toJson())),
        "standards-body":
            List<dynamic>.from(standardsBody.map((x) => x.toJson())),
        "edition-number": editionNumber,
        "group-title": List<dynamic>.from(groupTitle.map((x) => x)),
        "reference-count": referenceCount,
        "publisher": publisher,
        "issue": issue,
        "isbn-type": List<dynamic>.from(isbnType.map((x) => x.toJson())),
        "license": List<dynamic>.from(license.map((x) => x.toJson())),
        "funder": List<dynamic>.from(funder.map((x) => x.toJson())),
        "content-domain": contentDomain.toJson(),
        "chair": List<dynamic>.from(chair.map((x) => x.toJson())),
        "short-container-title": shortContainerTitle,
        "accepted": accepted.toJson(),
        "content-updated": contentUpdated.toJson(),
        "published-print": publishedPrint.toJson(),
        "abstract": itemAbstract,
        "DOI": doi,
        "type": type,
        "created": created.toJson(),
        "approved": approved.toJson(),
        "page": page,
        "update-policy": updatePolicy,
        "source": source,
        "is-referenced-by-count": isReferencedByCount,
        "title": List<dynamic>.from(title.map((x) => x)),
        "prefix": prefix,
        "volume": volume,
        "clinical-trial-number":
            List<dynamic>.from(clinicalTrialNumber.map((x) => x.toJson())),
        "author": List<dynamic>.from(author.map((x) => x.toJson())),
        "member": member,
        "content-created": contentCreated.toJson(),
        "published-online": publishedOnline.toJson(),
        "reference": reference.toJson(),
        "container-title": List<dynamic>.from(containerTitle.map((x) => x)),
        "review": review.toJson(),
        "original-title": List<dynamic>.from(originalTitle.map((x) => x)),
        "language": language,
        "link": List<dynamic>.from(link.map((x) => x.toJson())),
        "deposited": deposited.toJson(),
        "score": score,
        "degree": degree,
        "subtitle": List<dynamic>.from(subtitle.map((x) => x)),
        "translator": List<dynamic>.from(translator.map((x) => x.toJson())),
        "free-to-read": freeToRead.toJson(),
        "editor": List<dynamic>.from(editor.map((x) => x.toJson())),
        "component-number": componentNumber,
        "short-title": List<dynamic>.from(shortTitle.map((x) => x)),
        "issued": issued.toJson(),
        "ISBN": List<dynamic>.from(isbn.map((x) => x)),
        "references-count": referencesCount,
        "part-number": partNumber,
        "journal-issue": journalIssue.toJson(),
        "alternative-id": List<dynamic>.from(alternativeId.map((x) => x)),
        "URL": url,
        "archive": List<dynamic>.from(archive.map((x) => x)),
        "relation": relation.toJson(),
        "ISSN": List<dynamic>.from(issn.map((x) => x)),
        "issn-type": List<dynamic>.from(issnType.map((x) => x.toJson())),
        "subject": List<dynamic>.from(subject.map((x) => x)),
        "published-other": publishedOther.toJson(),
        "published": published.toJson(),
        "assertion": List<dynamic>.from(assertion.map((x) => x.toJson())),
        "subtype": subtype,
        "article-number": articleNumber,
      };
}

class Accepted {
  List<List<int>> dateParts;

  Accepted({
    required this.dateParts,
  });

  factory Accepted.fromJson(Map<String, dynamic> json) => Accepted(
        dateParts: List<List<int>>.from(
            json["date-parts"].map((x) => List<int>.from(x.map((x) => x)))),
      );

  Map<String, dynamic> toJson() => {
        "date-parts": List<dynamic>.from(
            dateParts.map((x) => List<dynamic>.from(x.map((x) => x)))),
      };
}

class Assertion {
  Group group;
  Explanation explanation;
  String name;
  String value;
  String url;
  int order;

  Assertion({
    required this.group,
    required this.explanation,
    required this.name,
    required this.value,
    required this.url,
    required this.order,
  });

  factory Assertion.fromJson(Map<String, dynamic> json) => Assertion(
        group: Group.fromJson(json["group"]),
        explanation: Explanation.fromJson(json["explanation"]),
        name: json["name"],
        value: json["value"],
        url: json["URL"],
        order: json["order"],
      );

  Map<String, dynamic> toJson() => {
        "group": group.toJson(),
        "explanation": explanation.toJson(),
        "name": name,
        "value": value,
        "URL": url,
        "order": order,
      };
}

class Explanation {
  String url;

  Explanation({
    required this.url,
  });

  factory Explanation.fromJson(Map<String, dynamic> json) => Explanation(
        url: json["URL"],
      );

  Map<String, dynamic> toJson() => {
        "URL": url,
      };
}

class Group {
  String name;
  String label;

  Group({
    required this.name,
    required this.label,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        name: json["name"],
        label: json["label"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "label": label,
      };
}

class Author {
  String orcid;
  String suffix;
  String given;
  String family;
  List<Affiliation> affiliation;
  String name;
  bool authenticatedOrcid;
  String prefix;
  String sequence;

  Author({
    required this.orcid,
    required this.suffix,
    required this.given,
    required this.family,
    required this.affiliation,
    required this.name,
    required this.authenticatedOrcid,
    required this.prefix,
    required this.sequence,
  });

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        orcid: json["ORCID"],
        suffix: json["suffix"],
        given: json["given"],
        family: json["family"],
        affiliation: List<Affiliation>.from(
            json["affiliation"].map((x) => Affiliation.fromJson(x))),
        name: json["name"],
        authenticatedOrcid: json["authenticated-orcid"],
        prefix: json["prefix"],
        sequence: json["sequence"],
      );

  Map<String, dynamic> toJson() => {
        "ORCID": orcid,
        "suffix": suffix,
        "given": given,
        "family": family,
        "affiliation": List<dynamic>.from(affiliation.map((x) => x.toJson())),
        "name": name,
        "authenticated-orcid": authenticatedOrcid,
        "prefix": prefix,
        "sequence": sequence,
      };
}

class Affiliation {
  String name;

  Affiliation({
    required this.name,
  });

  factory Affiliation.fromJson(Map<String, dynamic> json) => Affiliation(
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
      };
}

class ClinicalTrialNumber {
  String clinicalTrialNumber;
  String registry;
  String type;

  ClinicalTrialNumber({
    required this.clinicalTrialNumber,
    required this.registry,
    required this.type,
  });

  factory ClinicalTrialNumber.fromJson(Map<String, dynamic> json) =>
      ClinicalTrialNumber(
        clinicalTrialNumber: json["clinical-trial-number"],
        registry: json["registry"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "clinical-trial-number": clinicalTrialNumber,
        "registry": registry,
        "type": type,
      };
}

class ContentDomain {
  List<String> domain;
  bool crossmarkRestriction;

  ContentDomain({
    required this.domain,
    required this.crossmarkRestriction,
  });

  factory ContentDomain.fromJson(Map<String, dynamic> json) => ContentDomain(
        domain: List<String>.from(json["domain"].map((x) => x)),
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

class FreeToRead {
  Accepted startDate;
  Accepted endDate;

  FreeToRead({
    required this.startDate,
    required this.endDate,
  });

  factory FreeToRead.fromJson(Map<String, dynamic> json) => FreeToRead(
        startDate: Accepted.fromJson(json["start-date"]),
        endDate: Accepted.fromJson(json["end-date"]),
      );

  Map<String, dynamic> toJson() => {
        "start-date": startDate.toJson(),
        "end-date": endDate.toJson(),
      };
}

class Funder {
  String name;
  String doi;
  String doiAssertedBy;
  List<String> award;

  Funder({
    required this.name,
    required this.doi,
    required this.doiAssertedBy,
    required this.award,
  });

  factory Funder.fromJson(Map<String, dynamic> json) => Funder(
        name: json["name"],
        doi: json["DOI"],
        doiAssertedBy: json["doi-asserted-by"],
        award: List<String>.from(json["award"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "DOI": doi,
        "doi-asserted-by": doiAssertedBy,
        "award": List<dynamic>.from(award.map((x) => x)),
      };
}

class Institution {
  String name;
  List<String> place;
  List<String> department;
  List<String> acronym;

  Institution({
    required this.name,
    required this.place,
    required this.department,
    required this.acronym,
  });

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
        name: json["name"],
        place: List<String>.from(json["place"].map((x) => x)),
        department: List<String>.from(json["department"].map((x) => x)),
        acronym: List<String>.from(json["acronym"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "place": List<dynamic>.from(place.map((x) => x)),
        "department": List<dynamic>.from(department.map((x) => x)),
        "acronym": List<dynamic>.from(acronym.map((x) => x)),
      };
}

class NType {
  String type;
  List<String> value;

  NType({
    required this.type,
    required this.value,
  });

  factory NType.fromJson(Map<String, dynamic> json) => NType(
        type: json["type"],
        value: List<String>.from(json["value"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "value": List<dynamic>.from(value.map((x) => x)),
      };
}

class JournalIssue {
  String issue;

  JournalIssue({
    required this.issue,
  });

  factory JournalIssue.fromJson(Map<String, dynamic> json) => JournalIssue(
        issue: json["issue"],
      );

  Map<String, dynamic> toJson() => {
        "issue": issue,
      };
}

class License {
  String url;
  Created start;
  int delayInDays;
  String contentVersion;

  License({
    required this.url,
    required this.start,
    required this.delayInDays,
    required this.contentVersion,
  });

  factory License.fromJson(Map<String, dynamic> json) => License(
        url: json["URL"],
        start: Created.fromJson(json["start"]),
        delayInDays: json["delay-in-days"],
        contentVersion: json["content-version"],
      );

  Map<String, dynamic> toJson() => {
        "URL": url,
        "start": start.toJson(),
        "delay-in-days": delayInDays,
        "content-version": contentVersion,
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

class Reference {
  String issn;
  String standardsBody;
  String issue;
  String key;
  String seriesTitle;
  String isbnType;
  String doiAssertedBy;
  String firstPage;
  String isbn;
  String doi;
  String component;
  String articleTitle;
  String volumeTitle;
  String volume;
  String author;
  String standardDesignator;
  String year;
  String unstructured;
  String edition;
  String journalTitle;
  String issnType;

  Reference({
    required this.issn,
    required this.standardsBody,
    required this.issue,
    required this.key,
    required this.seriesTitle,
    required this.isbnType,
    required this.doiAssertedBy,
    required this.firstPage,
    required this.isbn,
    required this.doi,
    required this.component,
    required this.articleTitle,
    required this.volumeTitle,
    required this.volume,
    required this.author,
    required this.standardDesignator,
    required this.year,
    required this.unstructured,
    required this.edition,
    required this.journalTitle,
    required this.issnType,
  });

  factory Reference.fromJson(Map<String, dynamic> json) => Reference(
        issn: json["issn"],
        standardsBody: json["standards-body"],
        issue: json["issue"],
        key: json["key"],
        seriesTitle: json["series-title"],
        isbnType: json["isbn-type"],
        doiAssertedBy: json["doi-asserted-by"],
        firstPage: json["first-page"],
        isbn: json["isbn"],
        doi: json["doi"],
        component: json["component"],
        articleTitle: json["article-title"],
        volumeTitle: json["volume-title"],
        volume: json["volume"],
        author: json["author"],
        standardDesignator: json["standard-designator"],
        year: json["year"],
        unstructured: json["unstructured"],
        edition: json["edition"],
        journalTitle: json["journal-title"],
        issnType: json["issn-type"],
      );

  Map<String, dynamic> toJson() => {
        "issn": issn,
        "standards-body": standardsBody,
        "issue": issue,
        "key": key,
        "series-title": seriesTitle,
        "isbn-type": isbnType,
        "doi-asserted-by": doiAssertedBy,
        "first-page": firstPage,
        "isbn": isbn,
        "doi": doi,
        "component": component,
        "article-title": articleTitle,
        "volume-title": volumeTitle,
        "volume": volume,
        "author": author,
        "standard-designator": standardDesignator,
        "year": year,
        "unstructured": unstructured,
        "edition": edition,
        "journal-title": journalTitle,
        "issn-type": issnType,
      };
}

class Relation {
  AdditionalProp additionalProp1;
  AdditionalProp additionalProp2;
  AdditionalProp additionalProp3;

  Relation({
    required this.additionalProp1,
    required this.additionalProp2,
    required this.additionalProp3,
  });

  factory Relation.fromJson(Map<String, dynamic> json) => Relation(
        additionalProp1: AdditionalProp.fromJson(json["additionalProp1"]),
        additionalProp2: AdditionalProp.fromJson(json["additionalProp2"]),
        additionalProp3: AdditionalProp.fromJson(json["additionalProp3"]),
      );

  Map<String, dynamic> toJson() => {
        "additionalProp1": additionalProp1.toJson(),
        "additionalProp2": additionalProp2.toJson(),
        "additionalProp3": additionalProp3.toJson(),
      };
}

class AdditionalProp {
  String idType;
  String id;
  String assertedBy;

  AdditionalProp({
    required this.idType,
    required this.id,
    required this.assertedBy,
  });

  factory AdditionalProp.fromJson(Map<String, dynamic> json) => AdditionalProp(
        idType: json["id-type"],
        id: json["id"],
        assertedBy: json["asserted-by"],
      );

  Map<String, dynamic> toJson() => {
        "id-type": idType,
        "id": id,
        "asserted-by": assertedBy,
      };
}

class Review {
  String type;
  String runningNumber;
  String revisionRound;
  String stage;
  String competingInterestStatement;
  String recommendation;
  String language;

  Review({
    required this.type,
    required this.runningNumber,
    required this.revisionRound,
    required this.stage,
    required this.competingInterestStatement,
    required this.recommendation,
    required this.language,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        type: json["type"],
        runningNumber: json["running-number"],
        revisionRound: json["revision-round"],
        stage: json["stage"],
        competingInterestStatement: json["competing-interest-statement"],
        recommendation: json["recommendation"],
        language: json["language"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "running-number": runningNumber,
        "revision-round": revisionRound,
        "stage": stage,
        "competing-interest-statement": competingInterestStatement,
        "recommendation": recommendation,
        "language": language,
      };
}

class StandardsBody {
  String name;
  List<String> acronym;

  StandardsBody({
    required this.name,
    required this.acronym,
  });

  factory StandardsBody.fromJson(Map<String, dynamic> json) => StandardsBody(
        name: json["name"],
        acronym: List<String>.from(json["acronym"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "acronym": List<dynamic>.from(acronym.map((x) => x)),
      };
}

class UpdateTo {
  String label;
  String doi;
  String type;
  Created updated;

  UpdateTo({
    required this.label,
    required this.doi,
    required this.type,
    required this.updated,
  });

  factory UpdateTo.fromJson(Map<String, dynamic> json) => UpdateTo(
        label: json["label"],
        doi: json["DOI"],
        type: json["type"],
        updated: Created.fromJson(json["updated"]),
      );

  Map<String, dynamic> toJson() => {
        "label": label,
        "DOI": doi,
        "type": type,
        "updated": updated.toJson(),
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
