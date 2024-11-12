import '../models/crossref_journals_works_models.dart';

// Formats a given date to yyyy-mm-dd
String formatDate(DateTime? date) {
  if (date == null) return '';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String getAuthorsNames(List<PublicationAuthor> authors) {
  return authors.map((author) => '${author.given} ${author.family}').join(', ');
}
