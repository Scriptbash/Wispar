import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/unpaywall_api.dart';

class ArticleWebsite extends StatefulWidget {
  final String articleUrl;
  final String doi;

  const ArticleWebsite({Key? key, required this.articleUrl, required this.doi})
      : super(key: key);

  @override
  _ArticleWebsiteState createState() => _ArticleWebsiteState();
}

class _ArticleWebsiteState extends State<ArticleWebsite> {
  late Future<void> setupControllerFuture;
  late WebViewController? controller;
  late String pdfUrl = '';
  late String proxyUrl = '';

  @override
  void initState() {
    super.initState();
    setupControllerFuture = setupController();
  }

  Future<void> setupController() async {
    await checkUnpaywallAvailability();

    controller = await WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    if (pdfUrl.isNotEmpty) {
      controller!.loadRequest(Uri.parse(pdfUrl));
      _showSnackBar('The article was provided through Unpaywall');
    } else {
      controller!.loadRequest(Uri.parse(proxyUrl + widget.articleUrl));
      if (proxyUrl.isNotEmpty) {
        _showSnackBar('Forwarded through your institution proxy');
      }
    }
  }

  Future<void> checkUnpaywallAvailability() async {
    final Unpaywall result =
        await UnpaywallService.checkAvailability(widget.doi);
    if (result.pdfUrl.isNotEmpty) {
      setState(() {
        pdfUrl = result.pdfUrl;
      });
    } else {
      await loadProxyUrl();
    }
  }

  Future<void> loadProxyUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      proxyUrl = prefs.getString('institution_url') ?? '';
      proxyUrl = proxyUrl.replaceAll('\$@', '');
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.articleUrl),
      ),
      body: FutureBuilder<void>(
        future: setupControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return controller != null
                ? WebViewWidget(controller: controller!)
                : Center(child: CircularProgressIndicator());
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
