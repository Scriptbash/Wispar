import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../downloaded_card.dart';
import '../services/database_helper.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late Future<List<DownloadedCard>> _downloadedArticlesFuture;

  @override
  void initState() {
    super.initState();
    _downloadedArticlesFuture = getDownloadedArticles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(AppLocalizations.of(context)!.downloads),
      ),
      body: Center(
        child: FutureBuilder<List<DownloadedCard>>(
          future: _downloadedArticlesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              final downloadedArticles = snapshot.data!;
              if (downloadedArticles.isEmpty) {
                return Text('You do not have any downloads.');
              } else {
                return ListView.builder(
                  itemCount: downloadedArticles.length,
                  itemBuilder: (context, index) {
                    return downloadedArticles[index];
                  },
                );
              }
            } else {
              return Text('No downloaded articles found.');
            }
          },
        ),
      ),
    );
  }

  Future<List<DownloadedCard>> getDownloadedArticles() async {
    final databaseHelper = DatabaseHelper();

    return await databaseHelper.getDownloadedArticles();
  }
}
