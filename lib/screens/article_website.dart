import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/unpaywall_api.dart';
import 'pdf_reader.dart';
import '../publication_card.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class ArticleWebsite extends StatefulWidget {
  final PublicationCard publicationCard;

  const ArticleWebsite({Key? key, required this.publicationCard})
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
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      useOnDownloadStart: true,
      //iframeAllow: "camera; microphone",
      userAgent:
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0',
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
        await UnpaywallService.checkAvailability(widget.publicationCard.doi);
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
        pdfUrl = proxyUrl + widget.publicationCard.url;
      } else {
        pdfUrl = widget.publicationCard.url;
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
        appBar: AppBar(title: Text(widget.publicationCard.url)),
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

                    return NavigationActionPolicy.ALLOW;
                  },
                  onReceivedServerTrustAuthRequest:
                      (controller, challenge) async {
                    //print("challenge $challenge");
                    return ServerTrustAuthResponse(
                        action: ServerTrustAuthResponseAction.PROCEED);
                  },
                  onDownloadStartRequest: (controller, url) async {
                    if (url.mimeType == 'application/pdf') {
                      final response = await http.get(url.url);
                      if (response.body.startsWith('%PDF')) {
                        // Needed due to shenanigans of Elsevier and the likes
                        final appDir = await getApplicationDocumentsDirectory();
                        final pdfFile =
                            File('${appDir.path}/${url.suggestedFilename}');
                        await pdfFile.writeAsBytes(response.bodyBytes);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => PdfReader(
                            pdfUrl: pdfFile.path,
                            publicationCard: widget.publicationCard,
                          ),
                        ));
                      } else {
                        launchUrl(Uri.parse(pdfUrl));
                      }
                    } else {
                      debugPrint('The file is not a PDF. Not downloading.');
                    }
                  },
                  onLoadStop: (controller, url) async {
                    pullToRefreshController?.endRefreshing();
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                    controller
                        .evaluateJavascript(source: "document.title;")
                        .then((result) {
                      final title = result.trim();

                      /* Check if the title is "Host Needed"    
                      This will need to be improved as it will probably fail to
                       redirect if the institution has changed the error 
                       landing page or if the page is in a different language.*/

                      if (title == "Host Needed") {
                        // Load the page without the proxy URL
                        controller.loadUrl(
                          urlRequest: URLRequest(
                              url: WebUri(widget.publicationCard.url)),
                        );
                      }
                    }).catchError((error) {
                      debugPrint(
                          'Error occurred while evaluating JavaScript: $error');
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
                  onUpdateVisitedHistory:
                      (controller, url, androidIsReload) async {
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
