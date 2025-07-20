import 'package:flutter/material.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/services/unpaywall_api.dart';
import 'pdf_reader.dart';
import 'package:wispar/widgets/publication_card.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:wispar/services/logs_helper.dart';

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
        "Mozilla/5.0 (Android 16; Mobile; LG-M255; rv:140.0) Gecko/140.0 Firefox/140.0",
    supportMultipleWindows: true,
  );

  PullToRefreshController? pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  late String pdfUrl = '';
  late String proxyUrl = '';
  bool isReadyToLoad = false;
  final logger = LogsService().logger;

  String? _extractedPdfUrl;
  bool _isPdfInAppWebView = false;

  String? _currentWebViewCookies;
  WebUri? _currentWebViewUrl;

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
    String unpaywallPrefs = prefs.getString('unpaywall') ?? '1';

    // Check Unpaywall for PDF if enabled in the settings
    if (unpaywallPrefs == '1') {
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
      if (isReadyToLoad) {
        _currentWebViewUrl = WebUri(pdfUrl);
      }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.publicationCard.title),
        actions: [
          // Show 'Download PDF' button if an extracted URL exists
          if (_currentWebViewUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                if (_currentWebViewUrl != null &&
                    await canLaunchUrl(_currentWebViewUrl!)) {
                  await launchUrl(_currentWebViewUrl!,
                      mode: LaunchMode.externalApplication);
                } else {
                  _showSnackBar(
                      AppLocalizations.of(context)!.errorOpenExternalBrowser);
                }
              },
              tooltip: AppLocalizations.of(context)!.openExternalBrowser,
            ),
          if (_extractedPdfUrl != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: AppLocalizations.of(context)!.downloadFoundPdf,
              onPressed: () {
                _showDownloadOptions(
                    context, Uri.parse(_extractedPdfUrl!), null);
              },
            ),
        ],
      ),
      body: SafeArea(
          child: Column(children: <Widget>[
        Expanded(
          child: Stack(
            children: [
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
                          _extractedPdfUrl = null;
                          _isPdfInAppWebView = false;
                          _currentWebViewUrl = url;
                        });
                      },
                      onCreateWindow: (controller, createWindowRequest) async {
                        final Uri newWindowUri =
                            createWindowRequest.request.url!;
                        logger.info(
                            'Intercepted new window: ${newWindowUri.toString()}');

                        bool isPdfWindow = newWindowUri.path
                                .toLowerCase()
                                .endsWith('.pdf') ||
                            newWindowUri.queryParameters.containsKey('pdf') ||
                            (newWindowUri.toString().contains('/pdf/') &&
                                !newWindowUri.toString().contains('/epdf/')) ||
                            (newWindowUri.toString().contains('/pdfft') &&
                                newWindowUri.toString().contains('.pdf')) ||
                            (newWindowUri.toString().contains('/pdfdirect/') &&
                                newWindowUri.queryParameters
                                    .containsKey('download') &&
                                newWindowUri.queryParameters['download'] ==
                                    'true');

                        if (isPdfWindow) {
                          logger.info(
                              'New window is a PDF, loading in current WebView: $newWindowUri');
                          // Load the PDF URL into the current webViewController
                          // This will replace the current content with the PDF
                          await controller.loadUrl(
                              urlRequest: URLRequest(
                                  url: WebUri(newWindowUri.toString())));
                          setState(() {
                            _currentWebViewUrl =
                                WebUri(newWindowUri.toString());
                          });
                          return true;
                        } else {
                          logger.info(
                              'New window is not a PDF, launching externally: $newWindowUri');
                          if (await canLaunchUrl(newWindowUri)) {
                            launchUrl(newWindowUri,
                                mode: LaunchMode.externalApplication);
                            return true;
                          }
                        }
                        logger.warning(
                            'onCreateWindow: No handler for ${newWindowUri.toString()}, letting WebView create new window.');
                        return false;
                      },
                      onReceivedServerTrustAuthRequest:
                          (controller, challenge) async {
                        return ServerTrustAuthResponse(
                            action: ServerTrustAuthResponseAction.PROCEED);
                      },
                      onDownloadStartRequest: (controller, urlInfo) async {
                        final Uri downloadUri = urlInfo.url;
                        final String? mimeType = urlInfo.mimeType;
                        final String? suggestedFilename =
                            urlInfo.suggestedFilename;

                        logger.info(
                            'Download detected via onDownloadStartRequest: URL: $downloadUri, MIME: $mimeType, Filename: $suggestedFilename');

                        if (mimeType == 'application/pdf' ||
                            downloadUri.path.toLowerCase().endsWith('.pdf') ||
                            (downloadUri.queryParameters.containsKey('pdf') &&
                                !downloadUri.queryParameters
                                    .containsKey('needAccess')) ||
                            (downloadUri.toString().contains('/pdfdirect/') &&
                                downloadUri.queryParameters
                                    .containsKey('download') &&
                                downloadUri.queryParameters['download'] ==
                                    'true')) {
                          logger.info(
                              'PDF download request detected. Offering options to user.');
                          _showDownloadOptions(
                              context, downloadUri, suggestedFilename);
                          return;
                        } else {
                          logger.info(
                              'File type not supported for in-app handling via onDownloadStartRequest: $mimeType. Launching externally.');
                          if (await canLaunchUrl(downloadUri)) {
                            _showSnackBar(
                                AppLocalizations.of(context)!.downloadingFile);
                            launchUrl(downloadUri,
                                mode: LaunchMode.externalApplication);
                          } else {
                            _showSnackBar(
                                AppLocalizations.of(context)!.errorOpeningFile);
                          }
                        }
                      },
                      onLoadStop: (controller, url) async {
                        pullToRefreshController?.endRefreshing();
                        setState(() {
                          this.url = url.toString();
                          urlController.text = this.url;
                          _currentWebViewUrl = url;
                        });

                        await _extractCookiesFromWebView(url);

                        await _extractPdfLink(controller);

                        // Check if the current URL is a PDF
                        if (url?.path.toLowerCase().endsWith('.pdf') == true ||
                            (url?.queryParameters.containsKey('pdf') == true &&
                                !url!.queryParameters
                                    .containsKey('needAccess')) ||
                            (url?.toString().contains('/pdf/') == true &&
                                !url!.toString().contains('/epdf/')) ||
                            (url?.toString().contains('/pdfdirect/') == true &&
                                url!.queryParameters.containsKey('download') &&
                                url.queryParameters['download'] == 'true')) {
                          logger.info(
                              'Current URL ends with .pdf or strongly indicates a PDF. Marking as in-app PDF.');
                          setState(() {
                            _isPdfInAppWebView = true;
                          });
                        } else {
                          setState(() {
                            _isPdfInAppWebView = false;
                          });
                        }

                        if (url.toString().contains('/epdf/')) {
                          logger.info(
                              'epdf page detected, retrying PDF extraction after delay...');
                          Future.delayed(const Duration(seconds: 2),
                              () => _extractPdfLink(controller));
                        }

                        controller
                            .evaluateJavascript(source: "document.title;")
                            .then((result) {
                          final title = result.trim();
                          if (title == "Host Needed") {
                            logger.warning(
                                "Detected 'Host Needed' title, attempting without proxy for DOI: ${widget.publicationCard.doi}");
                            controller.loadUrl(
                              urlRequest: URLRequest(
                                  url: WebUri(widget.publicationCard.url)),
                            );
                          }
                        }).catchError((error) {});
                      },
                      onReceivedError: (controller, request, error) {
                        pullToRefreshController?.endRefreshing();
                        logger.severe(
                            'WebView Error: ${error.description}', error);
                        _showSnackBar(
                            AppLocalizations.of(context)!.webViewError);
                        setState(() {
                          _isPdfInAppWebView = false;
                          _currentWebViewUrl = null;
                        });
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
                          _currentWebViewUrl = url;
                        });
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        if (kDebugMode) {
                          print("WEBVIEW CONSOLE: ${consoleMessage.message}");
                        }
                      },
                    )
                  : Center(child: CircularProgressIndicator()),
              progress < 1.0
                  ? LinearProgressIndicator(value: progress)
                  : Container(),
            ],
          ),
        ),
      ])),
    );
  }

  // Extracts cookies from the current WebView URL
  Future<void> _extractCookiesFromWebView(WebUri? currentUrl) async {
    if (currentUrl == null) {
      _currentWebViewCookies = null;
      return;
    }

    try {
      final cookieManager = CookieManager.instance();
      final cookies = await cookieManager.getCookies(url: currentUrl);

      // Format cookies into a single string for HTTP header
      if (cookies.isNotEmpty) {
        _currentWebViewCookies = cookies
            .map((cookie) => '${cookie.name}=${cookie.value}')
            .join('; ');
        logger.info(
            'Extracted cookies for ${currentUrl.host}: $_currentWebViewCookies');
      } else {
        _currentWebViewCookies = null;
        logger.info('No cookies found for ${currentUrl.host}');
      }
    } catch (e, st) {
      logger.severe('Error extracting cookies from WebView: $e', e, st);
      _currentWebViewCookies = null;
    }
  }

  Future<void> _extractPdfLink(InAppWebViewController controller) async {
    String? pdfLink;
    logger
        .info('Starting _extractPdfLink for URL: ${await controller.getUrl()}');

    try {
      pdfLink = await controller.evaluateJavascript(source: r"""
                  var directPdfLink = document.querySelector('a[href*="/doi/pdfdirect/"][href*="?download=true"]');
                  if (directPdfLink) {
                      return directPdfLink.href;
                  }

                  var link = document.querySelector('a.read-link[data-track-action="Download PDF"], a[data-track-label="PdfLink"], a.pdf-link, a[href*="/doi/pdf/"]');
                  if (link) {
                      return link.href;
                  }
                  link = document.querySelector('a[aria-label*="Download PDF"]');
                  if (link) {
                      return link.href;
                  }
                  return null;
                  """) as String?;

      if (pdfLink == null || pdfLink.isEmpty) {
        pdfLink = await controller.evaluateJavascript(
                source:
                    "document.querySelector('meta[name=\"citation_pdf_url\"]')?.getAttribute('content');")
            as String?;
      }

      if (pdfLink == null || pdfLink.isEmpty) {
        pdfLink = await controller.evaluateJavascript(
                source:
                    "document.querySelector('link[rel=\"alternate\"][type=\"application/pdf\"]')?.getAttribute('href');")
            as String?;
      }

      if (pdfLink == null || pdfLink.isEmpty) {
        logger.fine('Trying to find PDF link in div.downloadPDFLink a');
        pdfLink = await controller.evaluateJavascript(
                source:
                    "document.querySelector('div.downloadPDFLink a')?.getAttribute('href');")
            as String?;
      }

      if (pdfLink != null && pdfLink.isNotEmpty) {
        Uri parsedLink = Uri.parse(pdfLink);
        if (!parsedLink.isAbsolute) {
          final currentUrl = await controller.getUrl();
          if (currentUrl != null) {
            pdfLink = currentUrl.resolveUri(parsedLink).toString();
          }
        }
        logger.info('Found PDF link in HTML: $pdfLink');
        if (mounted) {
          setState(() {
            _extractedPdfUrl = pdfLink;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _extractedPdfUrl = null;
          });
        }
        logger.info('No PDF link found in common selectors for current page.');
      }
    } catch (e, st) {
      logger.severe('Error extracting PDF link from HTML: $e', e, st);
      if (mounted) {
        setState(() {
          _extractedPdfUrl = null;
        });
      }
    }
  }

  Future<void> _showDownloadOptions(
      BuildContext context, Uri downloadUri, String? suggestedFilename) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding:
              MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.pdfDownloadOptionsTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.download_for_offline),
                title: Text(AppLocalizations.of(context)!.downloadToApp),
                subtitle:
                    Text(AppLocalizations.of(context)!.downloadToAppSubtitle),
                onTap: () async {
                  Navigator.pop(context);

                  if (!mounted) {
                    logger.warning(
                        'ArticleWebsiteState is not mounted, cannot proceed with download results.');
                    return;
                  }

                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                          AppLocalizations.of(this.context)!.downloadingFile),
                      duration: const Duration(seconds: 3),
                    ),
                  );

                  try {
                    final currentWebViewUrl = await webViewController?.getUrl();

                    Map<String, String> headers = {
                      'Host': downloadUri.host,
                      'User-Agent': settings.userAgent!,
                      'Accept':
                          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                      'Accept-Language':
                          'en-CA,fr;q=0.8,fr-FR;q=0.6,en-US;q=0.4,en;q=0.2',
                      'Accept-Encoding': 'gzip, deflate, br, zstd',
                      'DNT': '1',
                      'Sec-GPC': '1',
                      'Connection': 'keep-alive',
                      'Upgrade-Insecure-Requests': '1',
                      'Sec-Fetch-Dest': 'document',
                      'Sec-Fetch-Mode': 'navigate',
                      'Sec-Fetch-Site': 'none',
                      'Sec-Fetch-User': '?1',
                      'Priority': 'u=0, i',
                    };

                    if (currentWebViewUrl != null) {
                      headers['Referer'] = currentWebViewUrl.toString();
                      logger.info(
                          'Setting Referer header to: ${headers['Referer']}');
                    } else {
                      headers['Referer'] = downloadUri.origin;
                      logger.warning(
                          'currentWebViewUrl is null, using origin as Referer: ${headers['Referer']}');
                    }

                    if (_currentWebViewCookies != null &&
                        _currentWebViewCookies!.isNotEmpty) {
                      headers['Cookie'] = _currentWebViewCookies!;
                      logger
                          .info('Attaching cookies to HTTP download request.');
                      logger.info('Cookie Header: ${_currentWebViewCookies!}');
                    } else {
                      logger.warning(
                          'No cookies available for HTTP download. This might fail for authenticated content.');
                    }

                    logger.info('HTTP Request URL: $downloadUri');
                    logger
                        .info('Full HTTP Request Headers being sent: $headers');

                    final response =
                        await http.get(downloadUri, headers: headers);

                    if (!mounted) {
                      logger.warning(
                          'ArticleWebsiteState unmounted after HTTP request, cannot show results.');
                      return;
                    }

                    logger.info('HTTP Response Status: ${response.statusCode}');
                    logger.info('HTTP Response Headers: ${response.headers}');

                    if (response.statusCode == 200 &&
                        response.bodyBytes.isNotEmpty &&
                        response.bodyBytes[0] == 0x25 && // '%PDF' header check
                        response.bodyBytes[1] == 0x50 &&
                        response.bodyBytes[2] == 0x44 &&
                        response.bodyBytes[3] == 0x46) {
                      final appDir = await getApplicationDocumentsDirectory();
                      final fileName = suggestedFilename ??
                          'downloaded_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
                      final pdfFile = File('${appDir.path}/$fileName');
                      await pdfFile.writeAsBytes(response.bodyBytes);
                      if (mounted) {
                        Navigator.of(this.context).push(MaterialPageRoute(
                          builder: (context) => PdfReader(
                            pdfUrl: pdfFile.path,
                            publicationCard: widget.publicationCard,
                          ),
                        ));
                      }
                    } else {
                      logger.warning(
                          'HTTP download failed (status: ${response.statusCode}). Content was not a valid PDF header or server rejected.');

                      if (await canLaunchUrl(downloadUri)) {
                        launchUrl(downloadUri,
                            mode: LaunchMode.externalApplication);
                      }
                    }
                  } catch (e, st) {
                    logger.severe('Error during HTTP PDF download: $e', e, st);
                    _showSnackBar(AppLocalizations.of(this.context)!
                        .downloadFailedInAppViewer);
                    if (await canLaunchUrl(downloadUri)) {
                      launchUrl(downloadUri,
                          mode: LaunchMode.externalApplication);
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title:
                    Text(AppLocalizations.of(context)!.openInExternalPdfViewer),
                subtitle: Text(AppLocalizations.of(context)!
                    .openInExternalPdfViewerSubtitle),
                onTap: () async {
                  Navigator.pop(context);
                  if (await canLaunchUrl(downloadUri)) {
                    launchUrl(downloadUri,
                        mode: LaunchMode.externalApplication);
                  } else {}
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
