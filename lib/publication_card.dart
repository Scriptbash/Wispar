import 'package:flutter/material.dart';

class PublicationCard extends StatefulWidget {
  final String title;
  final String abstract;

  const PublicationCard({
    Key? key,
    required this.title,
    required this.abstract,
  }) : super(key: key);

  @override
  _PublicationCardState createState() => _PublicationCardState();
}

class _PublicationCardState extends State<PublicationCard> {
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            LayoutBuilder(
              builder: (context, constraints) {
                final abstractTextWidget = Text(
                  widget.abstract,
                  maxLines: 10,
                  overflow: TextOverflow.fade,
                );

                final textPainter = TextPainter(
                  text: TextSpan(
                    text: widget.abstract,
                    style: abstractTextWidget.style,
                  ),
                  maxLines: 10,
                  textDirection: TextDirection.ltr,
                );

                textPainter.layout(maxWidth: constraints.maxWidth);

                final abstractTextHeight = textPainter.size.height;
                final totalHeight = constraints.maxHeight - 16.0;

                if (abstractTextHeight < totalHeight) {
                  // If the abstract fits in the available height, use it
                  return abstractTextWidget;
                } else {
                  // Otherwise, use a constrained version of the abstract
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: totalHeight,
                    ),
                    child: abstractTextWidget,
                  );
                }
              },
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : null,
              ),
              onPressed: () {
                setState(() {
                  isLiked = !isLiked;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
