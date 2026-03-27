import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:wispar/services/database_helper.dart';
import 'package:wispar/services/sync_service.dart';

class CustomizeFeedBottomSheet extends StatefulWidget {
  final List<String> followedJournals;
  final List<String> moreJournals;
  final void Function(
    String feedName,
    Set<String> journals,
    String include,
    String exclude,
    String dateMode,
    String? dateAfter,
    String? dateBefore,
  ) onApply;

  final String? initialName;
  final String? initialInclude;
  final String? initialExclude;
  final Set<String>? initialSelectedJournals;
  final String? initialDateMode;
  final String? initialDateAfter;
  final String? initialDateBefore;
  final int? feedId;

  const CustomizeFeedBottomSheet(
      {super.key,
      required this.followedJournals,
      required this.moreJournals,
      required this.onApply,
      this.initialName,
      this.initialInclude,
      this.initialExclude,
      this.initialSelectedJournals,
      this.initialDateMode,
      this.initialDateAfter,
      this.initialDateBefore,
      this.feedId});

  @override
  CustomizeFeedBottomSheetState createState() =>
      CustomizeFeedBottomSheetState();
}

class CustomizeFeedBottomSheetState extends State<CustomizeFeedBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _includeController;
  late TextEditingController _excludeController;
  final TextEditingController _includeKeywordsController =
      TextEditingController();
  final TextEditingController _excludeKeywordsController =
      TextEditingController();

  final List<String> _includeChips = [];
  final List<String> _excludeChips = [];
  Set<String> _selectedJournals = {};
  bool _showMoreJournals = false;

  DateTime? _publishedDateAfter;
  DateTime? _publishedDateBefore;
  String _dateMode = 'none';

  @override
  void initState() {
    super.initState();

    _dateMode = widget.initialDateMode ?? 'none';

    if (widget.initialDateAfter != null &&
        widget.initialDateAfter!.isNotEmpty) {
      _publishedDateAfter = DateTime.tryParse(widget.initialDateAfter!);
    }

    if (widget.initialDateBefore != null &&
        widget.initialDateBefore!.isNotEmpty) {
      _publishedDateBefore = DateTime.tryParse(widget.initialDateBefore!);
    }

    _nameController = TextEditingController(text: widget.initialName ?? '');
    _includeController =
        TextEditingController(text: widget.initialInclude ?? '');
    _excludeController =
        TextEditingController(text: widget.initialExclude ?? '');

    _selectedJournals = widget.initialSelectedJournals != null
        ? Set<String>.from(widget.initialSelectedJournals!)
        : Set<String>.from(widget.followedJournals);

    if (_includeController.text.isNotEmpty) {
      _includeChips.addAll(_includeController.text.split(RegExp(r'\s+')));
    }
    if (_excludeController.text.isNotEmpty) {
      _excludeChips.addAll(_excludeController.text.split(RegExp(r'\s+')));
    }

    _includeKeywordsController.addListener(() {
      final text = _includeKeywordsController.text;
      if (text.endsWith(' ')) {
        final keyword = text.trim();
        if (keyword.isNotEmpty && !_includeChips.contains(keyword)) {
          setState(() {
            _includeChips.add(keyword);
          });
        }
        _includeKeywordsController.clear();
      }
    });

    _excludeKeywordsController.addListener(() {
      final text = _excludeKeywordsController.text;
      if (text.endsWith(' ')) {
        final keyword = text.trim();
        if (keyword.isNotEmpty && !_excludeChips.contains(keyword)) {
          setState(() {
            _excludeChips.add(keyword);
          });
        }
        _excludeKeywordsController.clear();
      }
    });
  }

  void _toggleSelectAllFollowed() {
    setState(() {
      if (_selectedJournals.containsAll(widget.followedJournals)) {
        _selectedJournals.removeAll(widget.followedJournals);
      } else {
        _selectedJournals.addAll(widget.followedJournals);
      }
    });
  }

  void _toggleSelectAllMore() {
    setState(() {
      if (_selectedJournals.containsAll(widget.moreJournals)) {
        _selectedJournals.removeAll(widget.moreJournals);
      } else {
        _selectedJournals.addAll(widget.moreJournals);
      }
    });
  }

  Future<void> _pickDate(BuildContext context, bool isAfter) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isAfter) {
          _publishedDateAfter = picked;
        } else {
          _publishedDateBefore = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.45, // Start at 45% of screen height
        minChildSize: 0.20, // Can drag down to 20%
        maxChildSize: 0.90, // Can drag up to 90%
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: MediaQuery.of(context).viewInsets,
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: Colors.grey[400]),
                        ),
                      ),
                      Text(AppLocalizations.of(context)!.customizeFeed,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.feedName,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.followedJournals,
                              style: Theme.of(context).textTheme.labelLarge),
                          TextButton(
                            onPressed: _toggleSelectAllFollowed,
                            child: Text(_selectedJournals
                                    .containsAll(widget.followedJournals)
                                ? AppLocalizations.of(context)!.clearAll
                                : AppLocalizations.of(context)!.selectAll),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.followedJournals.map((name) {
                          return FilterChip(
                            label: Text(name),
                            selected: _selectedJournals.contains(name),
                            onSelected: (selected) {
                              setState(() {
                                selected
                                    ? _selectedJournals.add(name)
                                    : _selectedJournals.remove(name);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(AppLocalizations.of(context)!.moreJournals,
                            style: Theme.of(context).textTheme.labelLarge),
                        trailing: Icon(
                          _showMoreJournals
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        onTap: () => setState(
                            () => _showMoreJournals = !_showMoreJournals),
                      ),
                      if (_showMoreJournals) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _toggleSelectAllMore,
                              child: Text(_selectedJournals
                                      .containsAll(widget.moreJournals)
                                  ? AppLocalizations.of(context)!.clearAll
                                  : AppLocalizations.of(context)!.selectAll),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.moreJournals.map((name) {
                            return FilterChip(
                              label: Text(name),
                              selected: _selectedJournals.contains(name),
                              onSelected: (selected) {
                                setState(() {
                                  selected
                                      ? _selectedJournals.add(name)
                                      : _selectedJournals.remove(name);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 24),
                      // Include keywords
                      Text(AppLocalizations.of(context)!.includeKeywords,
                          style: Theme.of(context).textTheme.labelLarge),
                      Wrap(
                        spacing: 8,
                        children: _includeChips.map((chip) {
                          return FilterChip(
                            label: Text(chip),
                            selected: true,
                            onSelected: (_) {},
                            onDeleted: () =>
                                setState(() => _includeChips.remove(chip)),
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
                      TextField(
                        controller: _includeKeywordsController,
                        decoration: InputDecoration(
                            hintText:
                                AppLocalizations.of(context)!.typePressSpace),
                      ),
                      const SizedBox(height: 16),
                      // Exclude keywords
                      Text(AppLocalizations.of(context)!.excludeKeywords,
                          style: Theme.of(context).textTheme.labelLarge),
                      Wrap(
                        spacing: 8,
                        children: _excludeChips.map((chip) {
                          return FilterChip(
                            label: Text(chip),
                            selected: true,
                            onSelected: (_) {},
                            onDeleted: () =>
                                setState(() => _excludeChips.remove(chip)),
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
                      TextField(
                        controller: _excludeKeywordsController,
                        decoration: InputDecoration(
                            hintText:
                                AppLocalizations.of(context)!.typePressSpace),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        initialValue: _dateMode,
                        items: [
                          DropdownMenuItem(
                              value: 'none',
                              child:
                                  Text(AppLocalizations.of(context)!.noFilter)),
                          DropdownMenuItem(
                              value: 'after',
                              child: Text(AppLocalizations.of(context)!
                                  .publishedAfter)),
                          DropdownMenuItem(
                              value: 'before',
                              child: Text(AppLocalizations.of(context)!
                                  .publishedBefore)),
                          DropdownMenuItem(
                              value: 'between',
                              child: Text(AppLocalizations.of(context)!
                                  .publishedBetween)),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _dateMode = value!;
                            if (_dateMode == 'none') {
                              _publishedDateAfter = null;
                              _publishedDateBefore = null;
                            }
                          });
                        },
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)!.publicationDate),
                      ),
                      const SizedBox(height: 8),
                      if (_dateMode == 'after' || _dateMode == 'between')
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListTile(
                            title: Text(_publishedDateAfter == null
                                ? AppLocalizations.of(context)!.selectStartDate
                                : _publishedDateAfter!
                                    .toIso8601String()
                                    .split('T')[0]),
                            trailing: Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onTap: () => _pickDate(context, true),
                          ),
                        ),

                      if (_dateMode == 'before' || _dateMode == 'between')
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListTile(
                            title: Text(_publishedDateBefore == null
                                ? AppLocalizations.of(context)!.selectEndDate
                                : _publishedDateBefore!
                                    .toIso8601String()
                                    .split('T')[0]),
                            trailing: Icon(Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary),
                            onTap: () => _pickDate(context, false),
                          ),
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FloatingActionButton.extended(
                      onPressed: () async {
                        final db = DatabaseHelper();
                        final syncManager = SyncManager();
                        final feedName = _nameController.text.trim();
                        final include = _includeChips.join(' ');
                        final exclude = _excludeChips.join(' ');

                        if (feedName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .errorFeedNameEmpty)),
                          );
                          return;
                        }

                        // Check for duplicate name
                        final existingFilters = await db.getFeedFilters();
                        final nameExists = existingFilters.any((f) =>
                            (f['name'] as String).toLowerCase() ==
                            feedName.toLowerCase());

                        if (nameExists &&
                            (widget.initialName == null ||
                                widget.initialName!.toLowerCase() !=
                                    feedName.toLowerCase())) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .errorFeedNameAlreadyExists)),
                          );
                          return;
                        }

                        if (widget.initialName != null) {
                          await db.updateFeedFilter(
                            id: widget.feedId!,
                            name: feedName,
                            include: include,
                            exclude: exclude,
                            journals: _selectedJournals,
                            dateMode: _dateMode,
                            dateAfter: _publishedDateAfter?.toIso8601String(),
                            dateBefore: _publishedDateBefore?.toIso8601String(),
                          );
                          syncManager.triggerBackgroundSync();
                        } else {
                          await db.insertFeedFilter(
                            name: feedName,
                            include: include,
                            exclude: exclude,
                            journals: _selectedJournals,
                            dateMode: _dateMode,
                            dateAfter: _publishedDateAfter?.toIso8601String(),
                            dateBefore: _publishedDateBefore?.toIso8601String(),
                          );
                          syncManager.triggerBackgroundSync();
                        }

                        widget.onApply(
                          feedName,
                          _selectedJournals,
                          include,
                          exclude,
                          _dateMode,
                          _publishedDateAfter?.toIso8601String(),
                          _publishedDateBefore?.toIso8601String(),
                        );
                        Navigator.pop(context);
                      },
                      label: Text(AppLocalizations.of(context)!.save),
                      icon: const Icon(Icons.check),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _includeController.dispose();
    _excludeController.dispose();
    _includeKeywordsController.dispose();
    _excludeKeywordsController.dispose();
    super.dispose();
  }
}
