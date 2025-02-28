import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AbstractScraper {
  Completer<String?> _completer = Completer<String?>();

  Future<String?> scrapeAbstract(String url) async {
    _completer = Completer<String?>();

    HeadlessInAppWebView? headlessWebView;

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      onLoadStop: (controller, loadedUrl) async {
        await Future.delayed(Duration(seconds: 3)); // Allow JS-loaded content

        if (_completer.isCompleted) return;

        try {
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
          abstractText = abstractText!
              .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
              .replaceAll(RegExp(r'^\s*abstract[:.\s]*', caseSensitive: false),
                  '') // Remove leading "Abstract"
              .trim();

          _completer.complete(abstractText);
        } catch (e) {
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
