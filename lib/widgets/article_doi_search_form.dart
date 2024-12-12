import 'package:flutter/material.dart';

class DOISearchForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'DOI',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
