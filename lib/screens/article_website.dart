import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/unpaywall_api.dart';
import 'pdf_reader.dart';
import '../widgets/publication_card.dart';
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
    mediaPlaybackRequiresUserGesture: true,
    javaScriptEnabled: true,
    javaScriptCanOpenWindowsAutomatically: true,
    useOnDownloadStart: true,
    iframeAllowFullscreen: true,
    userAgent:
        "Mozilla/5.0 (Android 15; Mobile; rv:133.0) Gecko/133.0 Firefox/133.0",
  );

  PullToRefreshController? pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  late String pdfUrl = '';
  late String proxyUrl = '';
  bool isReadyToLoad = false;

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
    final prefs = await SharedPreferences.getInstance();
    String unpaywallPrefs = prefs.getString('unpaywall') ?? 'Enabled';

    // Check Unpaywall for PDF if enabled in the settings
    if (unpaywallPrefs == 'Enabled') {
      final Unpaywall result =
          await UnpaywallService.checkAvailability(widget.publicationCard.doi);
      if (result.pdfUrl.isNotEmpty) {
        setState(() {
          pdfUrl = result.pdfUrl;
        });
        _showSnackBar(AppLocalizations.of(context)!.unpaywallarticle);
      }
    }
    // If no PDF from Unpaywall or Unpaywall is disabled, check the proxy
    if (pdfUrl.isEmpty) {
      await loadProxyUrl();
      if (proxyUrl.isNotEmpty) {
        setState(() {
          pdfUrl = proxyUrl + widget.publicationCard.url;
        });
        _showSnackBar(AppLocalizations.of(context)!.forwardedproxy);
      } else {
        pdfUrl = widget.publicationCard.url;
      }
    }
    setState(() {
      isReadyToLoad =
          pdfUrl.isNotEmpty; // Ensure WebView only loads when URL is ready
    });
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
        appBar: AppBar(title: Text(widget.publicationCard.url)),
        body: SafeArea(
            child: Column(children: <Widget>[
          Expanded(
            child: Stack(
              children: [
                // Only show the WebView once the URL is ready
                isReadyToLoad
                    ? InAppWebView(
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
                              await launchUrl(uri);
                              // and cancel the request
                              return NavigationActionPolicy.CANCEL;
                            }
                          }
                          return NavigationActionPolicy.ALLOW;
                        },
                        onReceivedServerTrustAuthRequest:
                            (controller, challenge) async {
                          return ServerTrustAuthResponse(
                              action: ServerTrustAuthResponseAction.PROCEED);
                        },
                        onDownloadStartRequest: (controller, url) async {
                          if (url.mimeType == 'application/pdf') {
                            final response = await http.get(url.url);
                            if (response.body.startsWith('%PDF')) {
                              // Needed due to shenanigans of Elsevier and the likes
                              final appDir =
                                  await getApplicationDocumentsDirectory();
                              final pdfFile = File(
                                  '${appDir.path}/${url.suggestedFilename}');
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
                            debugPrint(
                                'The file is not a PDF. Not downloading.');
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
                      )
                    : Center(
                        child:
                            CircularProgressIndicator()), // Show progress while loading
                progress < 1.0
                    ? LinearProgressIndicator(value: progress)
                    : Container(),
              ],
            ),
          ),
        ])));
  }
}
