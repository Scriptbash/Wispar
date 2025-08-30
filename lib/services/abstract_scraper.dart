import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './string_format_helper.dart';
import './logs_helper.dart';

class AbstractScraper {
  Completer<String?> _completer = Completer<String?>();

  Future<String?> scrapeAbstract(String url) async {
    final logger = LogsService().logger;
    _completer = Completer<String?>();

    HeadlessInAppWebView? headlessWebView;

    final prefs = await SharedPreferences.getInstance();
    bool overrideUA = prefs.getBool('overrideUserAgent') ?? false;
    String? customUA = prefs.getString('customUserAgent');

    String userAgent;
    if (overrideUA && customUA != null && customUA.isNotEmpty) {
      userAgent = customUA;
    } else {
      if (Platform.isAndroid) {
        userAgent =
            "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Mobile Safari/537.3";
      } else if (Platform.isIOS) {
        userAgent =
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_3_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3.1 Mobile/15E148 Safari/604";
      } else if (Platform.isMacOS) {
        userAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.3";
      } else if (Platform.isWindows) {
        userAgent =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.3";
      } else if (Platform.isLinux) {
        userAgent =
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.3";
      } else {
        userAgent =
            "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0 Mobile Safari/537.36";
      }
    }

    headlessWebView = HeadlessInAppWebView(
      initialSettings: InAppWebViewSettings(
        userAgent: userAgent,
      ),
      initialUrlRequest: URLRequest(url: WebUri(url)),
      onLoadStop: (controller, loadedUrl) async {
        await Future.delayed(Duration(seconds: 3)); // Allow JS-loaded content

        if (_completer.isCompleted) return;

        try {
          logger
              .info("Attempting to scrape missing abstract from ${loadedUrl}");
          String? abstractText = await controller.evaluateJavascript(
            source: """
              (() => {
                function extractFullText(element) {
                  if (!element) return null;
                  return element.innerText.trim();
                }

                // Special case: Springer (Abstract is inside c-article-section__content)
                let springerHeader = document.querySelector('h2.c-article-section__title');
                if (springerHeader && /abstract/i.test(springerHeader.innerText)) {
                  let springerAbstract = springerHeader.nextElementSibling;
                  if (springerAbstract && springerAbstract.classList.contains('c-article-section__content')) {
                    return extractFullText(springerAbstract);
                  }
                }

                // Special case: Elsevier (abstract is inside '.abstract.author')
                let elsevierAbstract = document.querySelector('.abstract.author');
                if (elsevierAbstract) {
                  return extractFullText(elsevierAbstract);
                }

                // General case: Look for any div/section with 'abstract' in class or id
                let abstractDiv = [...document.querySelectorAll('div, section')]
                  .find(el => /abstract/i.test(el.className) || /abstract/i.test(el.id));

                if (abstractDiv) {
                  return extractFullText(abstractDiv);
                }

                // Fallback to meta description
                let metaDesc = document.querySelector('meta[name="description"]');
                if (metaDesc) return metaDesc.content.trim();

                return null;
              })();
            """,
          );
          abstractText = cleanAbstract(abstractText!);
          logger.info('The missing abstract was successfully scraped.');
          _completer.complete(abstractText);
        } catch (e, stackTrace) {
          logger.severe(
              'The missing abstract could not be scraped.', e, stackTrace);
          _completer.completeError(e);
        } finally {
          await InAppWebViewController.clearAllCache();
          headlessWebView?.dispose();
        }
      },
    );

    await headlessWebView.run();
    return _completer.future;
  }
}
