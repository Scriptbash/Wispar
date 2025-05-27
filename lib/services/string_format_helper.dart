import '../models/crossref_journals_works_models.dart';
import './mathml_converter.dart';
import 'package:html/parser.dart' as html;

// Formats a given date to yyyy-mm-dd
String formatDate(DateTime? date) {
  if (date == null) return '';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String getAuthorsNames(List<PublicationAuthor> authors) {
  return authors.map((author) => '${author.given} ${author.family}').join(', ');
}

String cleanAbstract(String rawAbstract) {
  final converter = MathmlToLatexConverter();
  rawAbstract = converter.convert(rawAbstract);
  rawAbstract = html.parse(rawAbstract).body!.text;
  rawAbstract = rawAbstract.replaceAll(
    RegExp(r'<jats:title>.*?</jats:title>', dotAll: true),
    '',
  );

  // Replace LaTeX equations from <jats:inline-formula> with <jats:tex-math> into $...$
  rawAbstract = rawAbstract.replaceAllMapped(
    RegExp(
        r'<jats:inline-formula>.*?<jats:tex-math>(.*?)</jats:tex-math>.*?</jats:inline-formula>',
        dotAll: true),
    (match) {
      String tex = match[1]?.trim() ?? '';

      // Remove existing delimiters
      tex = tex.replaceAll(RegExp(r'^\$+|\$+$'), '');

      return '\$$tex\$';
    },
  );

  // Remove any other <jats:inline-formula> blocks like MathML
  rawAbstract = rawAbstract.replaceAll(
    RegExp(r'<jats:inline-formula>.*?</jats:inline-formula>', dotAll: true),
    '',
  );

  // Remove remaining XML/HTML tags
  rawAbstract = rawAbstract.replaceAll(RegExp(r'<[^>]+>'), '');

  // Remove leading "Abstract"
  rawAbstract = rawAbstract.replaceAll(
    RegExp(r'^\s*abstract[:.\s]*', caseSensitive: false),
    '',
  );

  rawAbstract = rawAbstract
      .replaceAll('&gt;', '>')
      .replaceAll('&lt;', '<')
      .replaceAll('&amp;', '&');

  // Remove extra spaces
  rawAbstract = rawAbstract.replaceAll(RegExp(r'\s+'), ' ');

  return rawAbstract.trim();
}

String cleanTitle(String rawTitle) {
  final converter = MathmlToLatexConverter();
  rawTitle = converter.convert(rawTitle);
  rawTitle = html.parse(rawTitle).body!.text;
  // Remove all HTML tags
  rawTitle = rawTitle.replaceAll(RegExp(r'<[^>]+>'), '');
  rawTitle = rawTitle
      .replaceAll('&gt;', '>')
      .replaceAll('&lt;', '<')
      .replaceAll('&amp;', '&');

  // Remove extra spaces
  rawTitle = rawTitle.replaceAll(RegExp(r'\s+'), ' ');

  return rawTitle.trim();
}
