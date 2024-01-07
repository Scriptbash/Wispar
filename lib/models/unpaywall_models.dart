// To parse this JSON data, do
//
//     final unpaywall = unpaywallFromJson(jsonString);

import 'dart:convert';

Unpaywall unpaywallFromJson(String str) => Unpaywall.fromJson(json.decode(str));

String unpaywallToJson(Unpaywall data) => json.encode(data.toJson());

class Unpaywall {
  String doi;
  String doiUrl;
  String title;
  String genre;
  bool isParatext;
  DateTime publishedDate;
  int year;
  String journalName;
  String journalIssns;
  String journalIssnL;
  bool journalIsOa;
  bool journalIsInDoaj;
  String publisher;
  bool isOa;
  String oaStatus;
  bool hasRepositoryCopy;
  OaLocation bestOaLocation;
  OaLocation firstOaLocation;
  List<OaLocation> oaLocations;
  List<dynamic> oaLocationsEmbargoed;
  DateTime updated;
  int dataStandard;
  List<ZAuthor> zAuthors;

  Unpaywall({
    required this.doi,
    required this.doiUrl,
    required this.title,
    required this.genre,
    required this.isParatext,
    required this.publishedDate,
    required this.year,
    required this.journalName,
    required this.journalIssns,
    required this.journalIssnL,
    required this.journalIsOa,
    required this.journalIsInDoaj,
    required this.publisher,
    required this.isOa,
    required this.oaStatus,
    required this.hasRepositoryCopy,
    required this.bestOaLocation,
    required this.firstOaLocation,
    required this.oaLocations,
    required this.oaLocationsEmbargoed,
    required this.updated,
    required this.dataStandard,
    required this.zAuthors,
  });

  factory Unpaywall.fromJson(Map<String, dynamic> json) => Unpaywall(
        doi: json["doi"],
        doiUrl: json["doi_url"],
        title: json["title"],
        genre: json["genre"],
        isParatext: json["is_paratext"],
        publishedDate: DateTime.parse(json["published_date"]),
        year: json["year"],
        journalName: json["journal_name"],
        journalIssns: json["journal_issns"],
        journalIssnL: json["journal_issn_l"],
        journalIsOa: json["journal_is_oa"],
        journalIsInDoaj: json["journal_is_in_doaj"],
        publisher: json["publisher"],
        isOa: json["is_oa"],
        oaStatus: json["oa_status"],
        hasRepositoryCopy: json["has_repository_copy"],
        bestOaLocation: OaLocation.fromJson(json["best_oa_location"]),
        firstOaLocation: OaLocation.fromJson(json["first_oa_location"]),
        oaLocations: List<OaLocation>.from(
            json["oa_locations"].map((x) => OaLocation.fromJson(x))),
        oaLocationsEmbargoed:
            List<dynamic>.from(json["oa_locations_embargoed"].map((x) => x)),
        updated: DateTime.parse(json["updated"]),
        dataStandard: json["data_standard"],
        zAuthors: List<ZAuthor>.from(
            json["z_authors"].map((x) => ZAuthor.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "doi": doi,
        "doi_url": doiUrl,
        "title": title,
        "genre": genre,
        "is_paratext": isParatext,
        "published_date":
            "${publishedDate.year.toString().padLeft(4, '0')}-${publishedDate.month.toString().padLeft(2, '0')}-${publishedDate.day.toString().padLeft(2, '0')}",
        "year": year,
        "journal_name": journalName,
        "journal_issns": journalIssns,
        "journal_issn_l": journalIssnL,
        "journal_is_oa": journalIsOa,
        "journal_is_in_doaj": journalIsInDoaj,
        "publisher": publisher,
        "is_oa": isOa,
        "oa_status": oaStatus,
        "has_repository_copy": hasRepositoryCopy,
        "best_oa_location": bestOaLocation.toJson(),
        "first_oa_location": firstOaLocation.toJson(),
        "oa_locations": List<dynamic>.from(oaLocations.map((x) => x.toJson())),
        "oa_locations_embargoed":
            List<dynamic>.from(oaLocationsEmbargoed.map((x) => x)),
        "updated": updated.toIso8601String(),
        "data_standard": dataStandard,
        "z_authors": List<dynamic>.from(zAuthors.map((x) => x.toJson())),
      };
}

class OaLocation {
  DateTime updated;
  String url;
  dynamic urlForPdf;
  String urlForLandingPage;
  String evidence;
  String license;
  String version;
  String hostType;
  bool isBest;
  dynamic pmhId;
  dynamic endpointId;
  dynamic repositoryInstitution;
  DateTime oaDate;

  OaLocation({
    required this.updated,
    required this.url,
    required this.urlForPdf,
    required this.urlForLandingPage,
    required this.evidence,
    required this.license,
    required this.version,
    required this.hostType,
    required this.isBest,
    required this.pmhId,
    required this.endpointId,
    required this.repositoryInstitution,
    required this.oaDate,
  });

  factory OaLocation.fromJson(Map<String, dynamic> json) => OaLocation(
        updated: DateTime.parse(json["updated"]),
        url: json["url"],
        urlForPdf: json["url_for_pdf"],
        urlForLandingPage: json["url_for_landing_page"],
        evidence: json["evidence"],
        license: json["license"],
        version: json["version"],
        hostType: json["host_type"],
        isBest: json["is_best"],
        pmhId: json["pmh_id"],
        endpointId: json["endpoint_id"],
        repositoryInstitution: json["repository_institution"],
        oaDate: DateTime.parse(json["oa_date"]),
      );

  Map<String, dynamic> toJson() => {
        "updated": updated.toIso8601String(),
        "url": url,
        "url_for_pdf": urlForPdf,
        "url_for_landing_page": urlForLandingPage,
        "evidence": evidence,
        "license": license,
        "version": version,
        "host_type": hostType,
        "is_best": isBest,
        "pmh_id": pmhId,
        "endpoint_id": endpointId,
        "repository_institution": repositoryInstitution,
        "oa_date":
            "${oaDate.year.toString().padLeft(4, '0')}-${oaDate.month.toString().padLeft(2, '0')}-${oaDate.day.toString().padLeft(2, '0')}",
      };
}

class ZAuthor {
  String? orcid;
  String given;
  String family;
  String sequence;
  bool? authenticatedOrcid;

  ZAuthor({
    this.orcid,
    required this.given,
    required this.family,
    required this.sequence,
    this.authenticatedOrcid,
  });

  factory ZAuthor.fromJson(Map<String, dynamic> json) => ZAuthor(
        orcid: json["ORCID"],
        given: json["given"],
        family: json["family"],
        sequence: json["sequence"],
        authenticatedOrcid: json["authenticated-orcid"],
      );

  Map<String, dynamic> toJson() => {
        "ORCID": orcid,
        "given": given,
        "family": family,
        "sequence": sequence,
        "authenticated-orcid": authenticatedOrcid,
      };
}
