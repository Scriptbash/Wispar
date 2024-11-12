import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SortByDialog extends StatefulWidget {
  final int initialSortBy;
  final ValueChanged<int> onSortByChanged;
  final List<String> sortOptions;

  SortByDialog({
    required this.initialSortBy,
    required this.onSortByChanged,
    required this.sortOptions,
  });

  @override
  _SortByDialogState createState() => _SortByDialogState();
}

class _SortByDialogState extends State<SortByDialog> {
  late int selectedSortBy;

  @override
  void initState() {
    super.initState();
    selectedSortBy = widget.initialSortBy;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.sortby),
      content: SingleChildScrollView(
        child: Column(
          children: widget.sortOptions.asMap().entries.map((entry) {
            int index = entry.key;
            String sortOption = entry.value;

            return RadioListTile<int>(
              value: index,
              groupValue: selectedSortBy,
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    selectedSortBy = value;
                    widget.onSortByChanged(selectedSortBy);
                  });
                  Navigator.pop(context); // Close the dialog
                }
              },
              title: Text(sortOption),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Utility function to show the SortByDialog
Future<void> showSortByDialog({
  required BuildContext context,
  required int initialSortBy,
  required ValueChanged<int> onSortByChanged,
  required List<String> sortOptions,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return SortByDialog(
        initialSortBy: initialSortBy,
        onSortByChanged: onSortByChanged,
        sortOptions: sortOptions,
      );
    },
  );
}
