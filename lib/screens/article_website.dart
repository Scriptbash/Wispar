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
import '../services/database_helper.dart';

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

  PullToRefreshController? pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  late String pdfUrl = '';
  late String proxyUrl = '';
  bool isReadyToLoad = false;
  final logger = LogsService().logger;
  final dbHelper = DatabaseHelper();

  String? _extractedPdfUrl;
  bool _isPdfInAppWebView = false;
  bool _isShowingDownloadOptions = false;

  String? _currentWebViewCookies;
  WebUri? _currentWebViewUrl;

  late InAppWebViewSettings settings;
  late final String _platformUserAgent;
  bool _overrideUA = false;
  String? _customUA;

  bool _isProxiedLoad = false;
  bool _showFeedbackButton = false;

  @override
  void initState() {
    super.initState();
    _initWebViewSettings();
    checkUnpaywallAvailability();

    pullToRefreshController = Platform.isAndroid || Platform.isIOS
        ? PullToRefreshController(
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
          )
        : null;
  }

  Future<void> _initWebViewSettings() async {
    _platformUserAgent = _getPlatformUserAgent();
    final prefs = await SharedPreferences.getInstance();
    _overrideUA = prefs.getBool('overrideUserAgent') ?? false;
    _customUA = prefs.getString('customUserAgent');

    settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: true,
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      useOnDownloadStart: true,
      iframeAllowFullscreen: true,
      userAgent: (_overrideUA && (_customUA?.isNotEmpty ?? false))
          ? _customUA
          : _platformUserAgent,
      supportMultipleWindows: true,
    );
  }

  String _getPlatformUserAgent() {
    if (Platform.isAndroid) {
      return "Mozilla/5.0 (Android 16; Mobile; LG-M255; rv:140.0) Gecko/140.0 Firefox/140.0";
    } else if (Platform.isIOS) {
      return "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile Safari/604.1";
    } else if (Platform.isMacOS) {
      return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko)";
    } else if (Platform.isWindows) {
      return "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:142.0) Gecko/20100101 Firefox/142.0";
    } else if (Platform.isLinux) {
      return "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.3";
    } else {
      return "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0 Mobile Safari/537.36";
    }
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
      await _initProxyAndLoadUrl();
    }
    setState(() {
      isReadyToLoad =
          pdfUrl.isNotEmpty; // Ensure WebView only loads when URL is ready
      if (isReadyToLoad) {
        _currentWebViewUrl = WebUri(pdfUrl);
      }
    });
  }

  // Handles the proxy logic
  Future<void> _initProxyAndLoadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String proxyUrlPref = prefs.getString('institution_url') ?? '';
    proxyUrlPref = proxyUrlPref.replaceAll('\$@', '');

    if (proxyUrlPref.isNotEmpty) {
      this.proxyUrl = proxyUrlPref;
      final baseUrl = Uri.parse(widget.publicationCard.url).host;
      final knownUrlEntry = await dbHelper.getKnownUrlByString(baseUrl);

      if (knownUrlEntry != null) {
        if (knownUrlEntry['proxySuccess'] == 1) {
          // Known to work, so apply the proxy.
          _isProxiedLoad = true;
          pdfUrl = '$proxyUrl${widget.publicationCard.url}';
          _showSnackBar(AppLocalizations.of(context)!.forwardedproxy);
        } else {
          // Known to not work, so load without the proxy.
          _isProxiedLoad = false;
          pdfUrl = widget.publicationCard.url;
        }
      } else {
        // When the base URL is not in the database, we try the proxy.
        _isProxiedLoad = true;
        pdfUrl = '$proxyUrl${widget.publicationCard.url}';
      }
    } else {
      _isProxiedLoad = false;
      pdfUrl = widget.publicationCard.url;
    }
  }

  Future<void> _handleUserFeedback(int proxySuccessValue, {WebUri? url}) async {
    final baseUrl = Uri.parse(widget.publicationCard.url).host;

    setState(() {
      _showFeedbackButton = false;
    });

    if (proxySuccessValue == 2) {
      final currentHost = url?.host;
      if (currentHost != null) {
        await dbHelper.insertKnownUrl(currentHost, proxySuccessValue);
      }
      return;
    } else {
      await dbHelper.insertKnownUrl(baseUrl, proxySuccessValue);
    }

    if (proxySuccessValue == 1) {
    } else if (proxySuccessValue == 0) {
      // Reload with the raw article URL only if the proxy attempt failed
      if (webViewController != null) {
        await webViewController!.loadUrl(
          urlRequest: URLRequest(url: WebUri(widget.publicationCard.url)),
        );
      }
    }
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
              icon: Image.asset(
                'assets/icon/pdf.png',
                width: 20,
                height: 20,
                color: Theme.of(context).iconTheme.color,
              ),
              tooltip: AppLocalizations.of(context)!.downloadFoundPdf,
              onPressed: () {
                _showDownloadOptions(context, Uri.parse(_extractedPdfUrl!));
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
                        controller.addJavaScriptHandler(
                          handlerName:
                              'downloadPdfUrl', // This matches the JS callHandler name
                          callback: (args) async {
                            final String pdfDirectUrl =
                                args[0]; // Get the URL from the JS arguments
                            logger.info(
                                "Received direct PDF URL from JavaScript: $pdfDirectUrl");
                            await controller.loadUrl(
                                urlRequest:
                                    URLRequest(url: WebUri(pdfDirectUrl)));

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .downloadStarting),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                        );
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
                        final WebUri? newWindowUri =
                            createWindowRequest.request.url;

                        if (newWindowUri == null ||
                            newWindowUri.toString().isEmpty) {
                          logger.warning(
                              'onCreateWindow: Incoming request URL is null or empty. Preventing popup.');
                          return false;
                        }

                        logger.info(
                            'Intercepted new window: ${newWindowUri.toString()}');

                        bool isPdfWindow = newWindowUri.path
                                .toLowerCase()
                                .endsWith('.pdf') ||
                            newWindowUri.queryParameters.containsKey('pdf') ||
                            (newWindowUri.toString().contains('/pdf/') ||
                                newWindowUri.toString().contains('/epdf/')) ||
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
                              urlRequest: URLRequest(url: newWindowUri));
                          setState(() {
                            _currentWebViewUrl = newWindowUri;
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
                            'onCreateWindow: No specific handler for ${newWindowUri.toString()}, preventing WebView from creating new window.');
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
                          _showDownloadOptions(context, downloadUri);
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

                        if (!_isPdfInAppWebView) {
                          _extractPdfLink(controller);
                        }

                        final baseUrl =
                            Uri.parse(widget.publicationCard.url).host;
                        final knownUrlEntry =
                            await dbHelper.getKnownUrlByString(baseUrl);

                        final currentHost = url?.host;
                        final knownCurrentHostEntry = currentHost != null
                            ? await dbHelper.getKnownUrlByString(currentHost)
                            : null;
                        if (_isProxiedLoad &&
                            knownUrlEntry == null &&
                            baseUrl != currentHost &&
                            (knownCurrentHostEntry == null ||
                                knownCurrentHostEntry['proxySuccess'] != 2)) {
                          setState(() {
                            _showFeedbackButton = true;
                          });
                        } else {
                          setState(() {
                            _showFeedbackButton = false;
                          });
                        }

                        // Check if the current URL is a PDF
                        if (url?.path.toLowerCase().endsWith('.pdf') == true ||
                            (url?.queryParameters.containsKey('pdf') == true &&
                                !url!.queryParameters
                                    .containsKey('needAccess')) ||
                            url?.toString().contains('/pdf/') == true ||
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

                        // --- Wiley-specific JavaScript injection for download ---
                        if (url
                                .toString()
                                .contains('onlinelibrary.wiley.com') &&
                            (url.toString().contains('/doi/pdfviewer/') ||
                                url.toString().contains('/doi/epdf/'))) {
                          logger.info(
                              'Wiley PDF viewer (or epdf) detected. Initiating delayed click attempt with polling for dropdown and download link.');

                          await controller.evaluateJavascript(source: """
                            (function() {
                                var checkAttempts = 0;
                                var maxAttempts = 40;
                                var intervalTime = 500;
                                var pdfUrlFound = false;
                                var checkInterval;

                                console.log('WEBVIEW_DEBUG: Initializing Wiley PDF URL extraction.');

                                function performExtraction() {
                                    if (pdfUrlFound) {
                                        clearInterval(checkInterval);
                                        return;
                                    }

                                    var downloadLinkSelector = 'a.download.drawerMenu--trigger.list-button[href*="/doi/pdfdirect/"][href*="?download=true"]';
                                    var downloadLink = document.querySelector(downloadLinkSelector);

                                    if (downloadLink && downloadLink.href) {
                                        console.log('WEBVIEW_DEBUG: Wiley Download link href found: ' + downloadLink.href);
                                        window.flutter_inappwebview.callHandler('downloadPdfUrl', downloadLink.href);
                                        pdfUrlFound = true;
                                        clearInterval(checkInterval);
                                    } else {
                                        checkAttempts++;
                                        console.log('WEBVIEW_DEBUG: Wiley Download link href NOT found yet. Attempt ' + checkAttempts + '.');
                                        if (checkAttempts >= maxAttempts) {
                                            console.log('WEBVIEW_DEBUG: Max attempts reached for PDF URL extraction. Stopping.');
                                            clearInterval(checkInterval);
                                        }
                                    }
                                }

                                checkInterval = setInterval(performExtraction, intervalTime);

                            })();
                          """);
                        }
                        // --- End Wiley-specific JavaScript injection ---

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
                                "Detected 'Host Needed' title for DOI: ${widget.publicationCard.doi}");
                          }
                        }).catchError((error) {});
                      },
                      onReceivedError: (controller, request, error) {
                        pullToRefreshController?.endRefreshing();
                        logger.severe(
                            'WebView Error: ${error.description}', error);

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
              if (_showFeedbackButton)
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'proxySuccessBtn',
                        onPressed: () => _handleUserFeedback(1),
                        label: Text(AppLocalizations.of(context)!.proxySuccess),
                        icon: Icon(Icons.check),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      SizedBox(height: 10),
                      FloatingActionButton.extended(
                        heroTag: 'proxyFailureBtn',
                        onPressed: () => _handleUserFeedback(0),
                        label: Text(AppLocalizations.of(context)!.proxyFailure),
                        icon: Icon(Icons.close),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      SizedBox(height: 10),
                      FloatingActionButton.extended(
                        heroTag: 'loginPageBtn',
                        onPressed: () =>
                            _handleUserFeedback(2, url: _currentWebViewUrl),
                        label: Text(AppLocalizations.of(context)!.proxyLogin),
                        icon: Icon(Icons.person),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
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
      BuildContext context, Uri downloadUri) async {
    if (_isShowingDownloadOptions) {
      logger.info(
          'Download options already showing or recently shown. Debouncing.');
      return;
    }

    _isShowingDownloadOptions = true;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
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
                      final currentWebViewUrl =
                          await webViewController?.getUrl();

                      Map<String, String> headers = {
                        'Host': downloadUri.host,
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
                      if (_overrideUA &&
                          _customUA != null &&
                          _customUA!.isNotEmpty) {
                        headers['User-Agent'] = _customUA!;
                      } /*else if (_webViewUserAgent != null) {
                        headers['User-Agent'] = _webViewUserAgent!;
                      } */
                      else {
                        headers['User-Agent'] = _getPlatformUserAgent();
                      }

                      if (currentWebViewUrl != null) {
                        headers['Referer'] = currentWebViewUrl.origin;
                        logger.info(
                            'Setting Referer header to: ${headers['Referer']} (from current page origin)');
                      } else {
                        headers['Referer'] = downloadUri.origin;
                        logger.warning(
                            'currentWebViewUrl is null, using origin of downloadUri as Referer: ${headers['Referer']}');
                      }

                      if (_currentWebViewCookies != null &&
                          _currentWebViewCookies!.isNotEmpty) {
                        headers['Cookie'] = _currentWebViewCookies!;
                        logger.info(
                            'Attaching cookies to HTTP download request.');
                        logger
                            .info('Cookie Header: ${_currentWebViewCookies!}');
                      } else {
                        logger.warning(
                            'No cookies available for HTTP download. This might fail for authenticated content.');
                      }

                      logger.info('HTTP Request URL: $downloadUri');
                      logger.info(
                          'Full HTTP Request Headers being sent: $headers');

                      final response =
                          await http.get(downloadUri, headers: headers);

                      if (!mounted) {
                        logger.warning(
                            'ArticleWebsiteState unmounted after HTTP request, cannot show results.');
                        return;
                      }

                      logger
                          .info('HTTP Response Status: ${response.statusCode}');
                      logger.info('HTTP Response Headers: ${response.headers}');

                      if (response.statusCode == 200 &&
                          response.bodyBytes.isNotEmpty &&
                          response.bodyBytes[0] ==
                              0x25 && // '%PDF' header check
                          response.bodyBytes[1] == 0x50 &&
                          response.bodyBytes[2] == 0x44 &&
                          response.bodyBytes[3] == 0x46) {
                        final prefs = await SharedPreferences.getInstance();
                        final useCustomPath =
                            prefs.getBool('useCustomDatabasePath') ?? false;
                        final customPath =
                            prefs.getString('customDatabasePath');
                        final String baseDirPath;

                        if (useCustomPath && customPath != null) {
                          baseDirPath = customPath;
                        } else {
                          final defaultAppDir =
                              await getApplicationDocumentsDirectory();
                          baseDirPath = defaultAppDir.path;
                        }
                        String cleanedDoi = widget.publicationCard.doi
                            .replaceAll(RegExp(r'[^\w\s.-]'), '_')
                            .replaceAll(' ', '_');

                        if (cleanedDoi.isEmpty) {
                          cleanedDoi =
                              'article_${DateTime.now().millisecondsSinceEpoch}';
                        }

                        final fileName = '$cleanedDoi.pdf';
                        final pdfFile = File('$baseDirPath/$fileName');
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
                        _showSnackBar(AppLocalizations.of(this.context)!
                            .downloadFailedInAppViewer);
                        logger.warning(
                            'HTTP download failed (status: ${response.statusCode}). Content was not a valid PDF header or server rejected.');

                        /*if (await canLaunchUrl(downloadUri)) {
                          launchUrl(downloadUri,
                              mode: LaunchMode.externalApplication);
                        }*/
                      }
                    } catch (e, st) {
                      logger.severe(
                          'Error during HTTP PDF download: $e', e, st);
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
                  title: Text(
                      AppLocalizations.of(context)!.openInExternalPdfViewer),
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
          ),
        );
      },
    ).whenComplete(() {
      _isShowingDownloadOptions = false;
    });
  }
}
