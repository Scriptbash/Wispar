import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SortOrderDialog extends StatelessWidget {
  final int initialSortOrder;
  final ValueChanged<int> onSortOrderChanged;
  final List<String> sortOrderOptions;

  SortOrderDialog({
    required this.initialSortOrder,
    required this.onSortOrderChanged,
    required this.sortOrderOptions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.sortorder),
      content: SingleChildScrollView(
        child: Column(
          children: List.generate(
            sortOrderOptions.length,
            (index) {
              return RadioListTile<int>(
                value: index,
                groupValue: initialSortOrder,
                onChanged: (int? value) {
                  if (value != null) {
                    onSortOrderChanged(value);
                    Navigator.pop(context);
                  }
                },
                title: Text(sortOrderOptions[index]),
              );
            },
          ),
        ),
      ),
    );
  }
}
