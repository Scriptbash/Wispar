import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArticleWebsite extends StatefulWidget {
  final String articleUrl;

  const ArticleWebsite({Key? key, required this.articleUrl}) : super(key: key);

  @override
  _ArticleWebsiteState createState() => _ArticleWebsiteState();
}

class _ArticleWebsiteState extends State<ArticleWebsite> {
  WebViewController? controller;
  late String proxyUrl = '';

  @override
  void initState() {
    super.initState();
    loadProxyUrl();
  }

  Future<void> loadProxyUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      proxyUrl = prefs.getString('institution_url') ?? '';
      proxyUrl = proxyUrl.replaceAll('\$@', '');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null && proxyUrl.isNotEmpty) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading bar.
            },
            onPageStarted: (String url) {},
            onPageFinished: (String url) {},
            onWebResourceError: (WebResourceError error) {},
            onNavigationRequest: (NavigationRequest request) {
              return NavigationDecision.navigate;
            },
          ),
        );

      // Load the article URL with the proxy when both are available.
      if (controller != null) {
        controller!.loadRequest(Uri.parse(proxyUrl + widget.articleUrl));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.articleUrl),
      ),
      body: controller != null
          ? WebViewWidget(controller: controller!)
          : Center(child: CircularProgressIndicator()),
    );
  }
}
