import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class CustomizeFeedBottomSheet extends StatefulWidget {
  final List<String> followedJournals;
  final List<String> moreJournals;
  final void Function(
    String feedName,
    Set<String> journals,
    String include,
    String exclude,
  ) onApply;

  final String? initialName;
  final String? initialInclude;
  final String? initialExclude;
  final Set<String>? initialSelectedJournals;
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
      this.feedId});

  @override
  _CustomizeFeedBottomSheetState createState() =>
      _CustomizeFeedBottomSheetState();
}

class _CustomizeFeedBottomSheetState extends State<CustomizeFeedBottomSheet> {
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

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName ?? '');
    _includeController =
        TextEditingController(text: widget.initialInclude ?? '');
    _excludeController =
        TextEditingController(text: widget.initialExclude ?? '');

    _selectedJournals = widget.initialSelectedJournals != null
        ? Set<String>.from(widget.initialSelectedJournals!)
        : Set<String>.from(widget.followedJournals);

    if (_includeController.text.isNotEmpty) {
      _includeChips.addAll(_includeController.text.split(RegExp(r'\\s+')));
    }
    if (_excludeController.text.isNotEmpty) {
      _excludeChips.addAll(_excludeController.text.split(RegExp(r'\\s+')));
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
                      Text('Customize feed',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Feed name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Followed journals',
                              style: Theme.of(context).textTheme.labelLarge),
                          TextButton(
                            onPressed: _toggleSelectAllFollowed,
                            child: Text(_selectedJournals
                                    .containsAll(widget.followedJournals)
                                ? 'Clear all'
                                : 'Select all'),
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
                        title: Text('More journals',
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
                                  ? 'Clear all'
                                  : 'Select all'),
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
                      Text('Include keywords',
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
                        decoration: const InputDecoration(
                            hintText: 'Type and press space...'),
                      ),
                      const SizedBox(height: 16),
                      // Exclude keywords
                      Text('Exclude keywords',
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
                        decoration: const InputDecoration(
                            hintText: 'Type and press space...'),
                      ),
                      const SizedBox(height: 24),
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
                        final feedName = _nameController.text.trim();
                        final include = _includeChips.join(' ');
                        final exclude = _excludeChips.join(' ');

                        if (feedName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter a feed name')),
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
                            const SnackBar(
                                content: Text(
                                    'A feed with this name already exists')),
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
                          );
                        } else {
                          await db.insertFeedFilter(
                            name: feedName,
                            include: include,
                            exclude: exclude,
                            journals: _selectedJournals,
                          );
                        }

                        widget.onApply(
                            feedName, _selectedJournals, include, exclude);
                        Navigator.pop(context);
                      },
                      label: const Text('Save'),
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
