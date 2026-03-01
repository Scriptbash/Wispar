class FeedFilter {
  final int id;
  final String name;
  final String include;
  final String exclude;
  final Set<String> journals;
  final String? dateMode;
  final String? dateAfter;
  final String? dateBefore;
  final String dateCreated;

  FeedFilter({
    required this.id,
    required this.name,
    required this.include,
    required this.exclude,
    required this.journals,
    this.dateMode,
    this.dateAfter,
    this.dateBefore,
    required this.dateCreated,
  });
}
