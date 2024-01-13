import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import './models/crossref_journals_works_models.dart';
import './screens/article_screen.dart';
import './services/database_helper.dart';

class PublicationCard extends StatefulWidget {
  final String title;
  final String abstract;
  final String journalTitle;
  final DateTime? publishedDate;
  final String doi;
  final List<PublicationAuthor> authors;
  final String? dateLiked;
  final VoidCallback? onFavoriteChanged;

  const PublicationCard({
    Key? key,
    required this.title,
    required this.abstract,
    required this.journalTitle,
    this.publishedDate,
    required this.doi,
    required List<PublicationAuthor> authors,
    this.dateLiked,
    this.onFavoriteChanged,
  })  : authors = authors,
        super(key: key);

  @override
  _PublicationCardState createState() => _PublicationCardState();
}

class _PublicationCardState extends State<PublicationCard> {
  bool isLiked = false;
  late DatabaseHelper databaseHelper;

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    checkIfLiked();
  }

  @override
  Widget build(BuildContext context) {
    // Skip the card creation if the publication title is empty
    if (widget.title.isEmpty) {
      return Container();
    }

    return GestureDetector(
      onTap: () {
        // Navigate to the ArticleScreen when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleScreen(
              doi: widget.doi,
              title: widget.title,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2.0,
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ListTile(
          contentPadding: EdgeInsets.all(16.0),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formattedDate(widget.publishedDate!),
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                widget.title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text(
                '${AppLocalizations.of(context)!.authors}: ${_getAuthorsNames(widget.authors)}',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              SizedBox(height: 8.0),
              LayoutBuilder(
                builder: (context, constraints) {
                  final abstractTextWidget = Text(
                    widget.abstract,
                    maxLines: 10,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.justify,
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
            children: [
              Expanded(
                child: Text(
                  'DOI: ${widget.doi}\n${AppLocalizations.of(context)!.publishedin} ${widget.journalTitle}${widget.dateLiked != null ? '\n${AppLocalizations.of(context)!.addedtoyourfav} ${widget.dateLiked}' : ''}',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : null,
                ),
                onPressed: () {
                  setState(() {
                    isLiked = !isLiked;
                  });
                  if (isLiked) {
                    databaseHelper.insertFavorite(widget);
                  } else {
                    databaseHelper.removeFavorite(widget.doi);
                  }

                  if (widget.onFavoriteChanged != null) {
                    widget.onFavoriteChanged!();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formattedDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getAuthorsNames(List<PublicationAuthor> authors) {
    return authors
        .map((author) => '${author.given} ${author.family}')
        .join(', ');
  }

  void checkIfLiked() async {
    bool liked = await databaseHelper.isArticleFavorite(widget.doi);
    setState(() {
      isLiked = liked;
    });
  }
}
