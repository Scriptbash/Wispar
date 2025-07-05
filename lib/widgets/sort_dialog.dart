import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';

class SortDialog extends StatefulWidget {
  final int initialSortBy;
  final int initialSortOrder;
  final List<String> sortByOptions;
  final List<String> sortOrderOptions;
  final ValueChanged<int> onSortByChanged;
  final ValueChanged<int> onSortOrderChanged;

  const SortDialog({
    required this.initialSortBy,
    required this.initialSortOrder,
    required this.sortByOptions,
    required this.sortOrderOptions,
    required this.onSortByChanged,
    required this.onSortOrderChanged,
  });

  @override
  _SortDialogState createState() => _SortDialogState();
}

class _SortDialogState extends State<SortDialog> {
  late int selectedSortBy;
  late int selectedSortOrder;

  @override
  void initState() {
    super.initState();
    selectedSortBy = widget.initialSortBy;
    selectedSortOrder = widget.initialSortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.sortby),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sort order toggle buttons
            Center(
              child: ToggleButtons(
                isSelected: List.generate(
                  widget.sortOrderOptions.length,
                  (index) => index == selectedSortOrder,
                ),
                onPressed: (int index) {
                  setState(() {
                    selectedSortOrder = index;
                  });
                  widget.onSortOrderChanged(index);
                },
                borderRadius: BorderRadius.circular(15),
                selectedColor: Theme.of(context).colorScheme.onPrimary,
                fillColor: Theme.of(context).colorScheme.primary,
                constraints: BoxConstraints(minHeight: 45, minWidth: 100),
                children: widget.sortOrderOptions
                    .map((label) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(label),
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: 24),

            // Sort by radio buttons
            ...widget.sortByOptions.asMap().entries.map((entry) {
              int index = entry.key;
              String option = entry.value;
              return RadioListTile<int>(
                title: Text(option),
                value: index,
                groupValue: selectedSortBy,
                onChanged: (value) {
                  setState(() {
                    selectedSortBy = value!;
                  });
                  widget.onSortByChanged(value!);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

Future<void> showSortDialog({
  required BuildContext context,
  required int initialSortBy,
  required int initialSortOrder,
  required List<String> sortByOptions,
  required List<String> sortOrderOptions,
  required ValueChanged<int> onSortByChanged,
  required ValueChanged<int> onSortOrderChanged,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return SortDialog(
        initialSortBy: initialSortBy,
        initialSortOrder: initialSortOrder,
        sortByOptions: sortByOptions,
        sortOrderOptions: sortOrderOptions,
        onSortByChanged: onSortByChanged,
        onSortOrderChanged: onSortOrderChanged,
      );
    },
  );
}
