import 'package:flutter/material.dart';
import 'package:wispar/services/openalex_api.dart';
import 'package:wispar/models/openalex_domain_models.dart';

class OpenAlexTopicSelector extends StatefulWidget {
  final ScrollController scrollController;
  final void Function({
    OpenAlexDomain? domain,
    OpenAlexField? field,
    OpenAlexSubfield? subfield,
    OpenAlexField? topic,
  }) onSelectionChanged;

  const OpenAlexTopicSelector({
    super.key,
    required this.scrollController,
    required this.onSelectionChanged,
  });

  @override
  State<OpenAlexTopicSelector> createState() => _OpenAlexTopicSelectorState();
}

class _OpenAlexTopicSelectorState extends State<OpenAlexTopicSelector> {
  late Future<List<OpenAlexDomain>> _domainsFuture;
  OpenAlexDomain? _selectedDomain;
  OpenAlexField? _selectedField;
  OpenAlexSubfield? _selectedSubfield;
  OpenAlexField? _selectedTopic;

  List<OpenAlexSubfield>? _subfields;

  final GlobalKey _fieldSectionKey = GlobalKey();
  final GlobalKey _subfieldSectionKey = GlobalKey();
  final GlobalKey _topicSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _domainsFuture = OpenAlexApi.getDomains();
  }

  IconData _getDomainIcon(String name) {
    switch (name.toLowerCase()) {
      case 'physical sciences':
        return Icons.science;
      case 'social sciences':
        return Icons.groups;
      case 'health sciences':
        return Icons.local_hospital;
      case 'life sciences':
        return Icons.eco;
      default:
        return Icons.category;
    }
  }

  Future<void> _loadSubfields(OpenAlexField field) async {
    setState(() {
      _subfields = null;
    });

    final results = await OpenAlexApi.getSubfieldsByFieldId(field.shortId);
    results.sort((a, b) => a.displayName.compareTo(b.displayName));

    setState(() {
      _subfields = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OpenAlexDomain>>(
      future: _domainsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text("Error loading domains");
        }

        final domains = (snapshot.data ?? [])
          ..sort((a, b) => a.displayName.compareTo(b.displayName));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Domain cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: domains.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 100,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final domain = domains[index];
                final isSelected = _selectedDomain?.id == domain.id;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDomain = isSelected ? null : domain;

                      _selectedField = null;
                      _selectedSubfield = null;
                      _subfields = null;
                    });
                    widget.onSelectionChanged(
                      domain: _selectedDomain,
                    );

                    _scrollToSection(_fieldSectionKey);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getDomainIcon(domain.displayName),
                          size: 25,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            domain.displayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Field cards
            if (_selectedDomain != null) ...[
              Text(
                _selectedDomain!.displayName,
                key: _fieldSectionKey,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final sortedFields = _selectedDomain!.fields.toList()
                  ..sort((a, b) => a.displayName.compareTo(b.displayName));

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedFields.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 100,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final field = sortedFields[index];
                    final isSelectedField = _selectedField?.id == field.id;

                    return InkWell(
                      onTap: () async {
                        setState(() {
                          _selectedField = isSelectedField ? null : field;
                          _selectedField = field;
                          _selectedSubfield = null;
                          _subfields = null;
                        });
                        if (_selectedField != null) {
                          await _loadSubfields(field);

                          _scrollToSection(_subfieldSectionKey);
                        }
                        widget.onSelectionChanged(
                          domain: _selectedDomain,
                          field: field,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelectedField
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                            width: isSelectedField ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            field.displayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),

              // Subfield cards
              if (_selectedField != null) ...[
                const SizedBox(height: 16),
                Text(
                  _selectedField!.displayName,
                  key: _subfieldSectionKey,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_subfields == null)
                  const Center(child: CircularProgressIndicator())
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _subfields!.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisExtent: 100,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      final subfield = _subfields![index];
                      final isSelectedSubfield =
                          _selectedSubfield?.id == subfield.id;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedSubfield = subfield;
                          });
                          widget.onSelectionChanged(
                            domain: _selectedDomain,
                            field: _selectedField,
                            subfield: subfield,
                          );
                          _scrollToSection(_topicSectionKey);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelectedSubfield
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                              width: isSelectedSubfield ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              subfield.displayName,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                if (_selectedSubfield != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _selectedSubfield!.displayName,
                    key: _topicSectionKey,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final sortedTopics = _selectedSubfield!.topics.toList()
                      ..sort((a, b) => a.displayName.compareTo(b.displayName));

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedTopics.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisExtent: 100,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final topic = sortedTopics[index];
                        final isSelectedTopic = _selectedTopic?.id == topic.id;

                        return InkWell(
                          onTap: () {
                            final topicField = OpenAlexField(
                              id: topic.id,
                              shortId: topic.id.split('/').last,
                              displayName: topic.displayName,
                            );

                            setState(() {
                              _selectedTopic = topicField;
                            });

                            widget.onSelectionChanged(
                              domain: _selectedDomain,
                              field: _selectedField,
                              subfield: _selectedSubfield,
                              topic: topicField,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelectedTopic
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).dividerColor,
                                width: isSelectedTopic ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                topic.displayName,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  })
                ]
              ]
            ],
          ],
        );
      },
    );
  }

  void _scrollToSection(GlobalKey key) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (key.currentContext != null && widget.scrollController.hasClients) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
