import 'package:http/http.dart' as http;
import 'package:wispar/models/journal_topics_models.dart';
import 'package:csv/csv.dart';

Future<List<JournalTopicsCsv>> fetchCsvCategories() async {
  final url =
      "https://raw.githubusercontent.com/hitfyd/ShowJCR/refs/heads/master/%E4%B8%AD%E7%A7%91%E9%99%A2%E5%88%86%E5%8C%BA%E8%A1%A8%E5%8F%8AJCR%E5%8E%9F%E5%A7%8B%E6%95%B0%E6%8D%AE%E6%96%87%E4%BB%B6/JCR2024-UTF8.csv";

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception("Failed to load CSV");
  }

  final csvRows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
      .convert(response.body);

  final List<JournalTopicsCsv> entries = [];

  for (int i = 1; i < csvRows.length; i++) {
    final row = csvRows[i];
    final journal = row[0].toString();
    final issn =
        (row[1].toString().toUpperCase() == 'N/A') ? '' : row[1].toString();
    final eissn =
        (row[2].toString().toUpperCase() == 'N/A') ? '' : row[2].toString();
    final categories = row[3].toString().split(';').map((c) {
      String clean = c.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
      return clean
          .toLowerCase()
          .split(' ')
          .map((word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1)}')
          .join(' ');
    }).toList();

    entries.add(JournalTopicsCsv(
      journal: journal,
      issn: issn,
      eissn: eissn,
      categories: categories,
    ));
  }

  return entries;
}
