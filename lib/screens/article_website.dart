import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/unpaywall_api.dart';
import 'pdf_reader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;

class ArticleWebsite extends StatefulWidget {
  final String articleUrl;
  final String doi;

  const ArticleWebsite({Key? key, required this.articleUrl, required this.doi})
      : super(key: key);

  @override
  _ArticleWebsiteState createState() => _ArticleWebsiteState();
}

class _ArticleWebsiteState extends State<ArticleWebsite> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      //iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  PullToRefreshController? pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  late String pdfUrl = '';
  late String proxyUrl = '';

  @override
  void initState() {
    super.initState();
    checkUnpaywallAvailability();
    pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.deepPurple,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );
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
    if (pdfUrl.isEmpty) {
      if (proxyUrl.isNotEmpty) {
        _showSnackBar(AppLocalizations.of(context)!.forwardedproxy);
        pdfUrl = proxyUrl + widget.articleUrl;
      } else {
        pdfUrl = widget.articleUrl;
      }
    } else {
      _showSnackBar(AppLocalizations.of(context)!.unpaywallarticle);
    }
    setupController();
  }

  Future<void> loadProxyUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      proxyUrl = prefs.getString('institution_url') ?? '';
      proxyUrl = proxyUrl.replaceAll('\$@', '');
    });
  }

  Future<String> checkMimeType(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = response.bodyBytes;
        final mime = lookupMimeType('', headerBytes: data);
        return mime ?? '';
      } else {
        return '';
      }
    } catch (e) {
      print('Error checking MIME type: $e');
      return '';
    }
  }

  void setupController() {
    if (pdfUrl.isNotEmpty) {
      webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(pdfUrl)));
    }
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
        appBar: AppBar(title: Text(widget.articleUrl)),
        body: SafeArea(
            child: Column(children: <Widget>[
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  key: webViewKey,
                  initialUrlRequest: URLRequest(url: WebUri(pdfUrl)),
                  initialSettings: settings,
                  pullToRefreshController: pullToRefreshController,
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  onPermissionRequest: (controller, request) async {
                    return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.GRANT);
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    var uri = navigationAction.request.url!;

                    if (![
                      "http",
                      "https",
                      "file",
                      "chrome",
                      "data",
                      "javascript",
                      "about"
                    ].contains(uri.scheme)) {
                      if (await canLaunchUrl(uri)) {
                        // Launch the App
                        await launchUrl(
                          uri,
                        );
                        // and cancel the request
                        return NavigationActionPolicy.CANCEL;
                      }
                    }

                    return NavigationActionPolicy.ALLOW;
                  },
                  onDownloadStartRequest: (controller, url) async {
                    String? mimeType = await checkMimeType(url.url.toString());
                    if (mimeType == 'application/pdf') {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => PdfViewer(
                          pdfUrl: url.url.toString(),
                          isDownloadable: true,
                        ),
                      ));
                    } else {
                      launchUrl(Uri.parse(pdfUrl),
                          mode: LaunchMode.inAppBrowserView);
                    }
                  },
                  onLoadStop: (controller, url) async {
                    pullToRefreshController?.endRefreshing();
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  onReceivedError: (controller, request, error) {
                    pullToRefreshController?.endRefreshing();
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      pullToRefreshController?.endRefreshing();
                    }
                    setState(() {
                      this.progress = progress / 100;
                      urlController.text = url;
                    });
                  },
                  onUpdateVisitedHistory: (controller, url, androidIsReload) {
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    if (kDebugMode) {
                      print(consoleMessage);
                    }
                  },
                ),
                progress < 1.0
                    ? LinearProgressIndicator(value: progress)
                    : Container(),
              ],
            ),
          ),
        ])));
  }
}
