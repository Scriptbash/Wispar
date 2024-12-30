import 'package:flutter/material.dart';

class DOISearchForm extends StatelessWidget {
  final TextEditingController doiController;

  DOISearchForm({required this.doiController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: doiController,
          decoration: InputDecoration(
            labelText: 'DOI',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
