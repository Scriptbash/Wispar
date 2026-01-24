import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/webview_env.dart';
import 'package:wispar/services/string_format_helper.dart';
import 'package:wispar/services/logs_helper.dart';

class AbstractScraper {
  Completer<Map<String, String?>> _completer =
      Completer<Map<String, String?>>();

  Future<Map<String, String?>> scrapeAbstractAndGraphical(String url,
      {bool textAbstract = true, bool graphicalAbstract = true}) async {
    final logger = LogsService().logger;
    _completer = Completer<Map<String, String?>>();

    HeadlessInAppWebView? headlessWebView;

    final prefs = await SharedPreferences.getInstance();
    bool overrideUA = prefs.getBool('overrideUserAgent') ?? false;
    String? customUA = prefs.getString('customUserAgent');

    String userAgent;
    if (overrideUA && customUA != null && customUA.isNotEmpty) {
      userAgent = customUA;
    } else if (Platform.isAndroid) {
      userAgent =
          "Mozilla/5.0 (Android 16; Mobile; LG-M255; rv:140.0) Gecko/140.0 Firefox/140.0";
    } else if (Platform.isIOS) {
      userAgent =
          "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile Safari/604.1";
    } else if (Platform.isMacOS) {
      userAgent =
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko)";
    } else if (Platform.isWindows) {
      userAgent =
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:142.0) Gecko/20100101 Firefox/142.0";
    } else if (Platform.isLinux) {
      userAgent =
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.3";
    } else {
      userAgent =
          "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0 Mobile Safari/537.36";
    }

    headlessWebView = HeadlessInAppWebView(
        initialSettings: InAppWebViewSettings(
          userAgent: userAgent,
        ),
        webViewEnvironment: Platform.isWindows ? webViewEnvironment : null,
        initialUrlRequest: URLRequest(url: WebUri(url)),
        onLoadStop: (controller, loadedUrl) async {
          await Future.delayed(const Duration(seconds: 3));
          if (_completer.isCompleted) return;

          try {
            logger.info("Scraping abstract/graphical abstract from $loadedUrl");

            final rawResult = await controller.evaluateJavascript(source: """
(() => {
  function extractFullText(element) {
    if (!element) return null;
    return element.innerText.trim();
  }

  let output = { abstract: null, graphicalAbstract: null };

  // ====== ABSTRACT ======
  if (${textAbstract ? "true" : "false"}) {
    let springerHeader = document.querySelector('h2.c-article-section__title');
    if (springerHeader && /abstract/i.test(springerHeader.innerText)) {
      let springerAbstract = springerHeader.nextElementSibling;
      if (springerAbstract && springerAbstract.classList.contains('c-article-section__content')) {
        output.abstract = extractFullText(springerAbstract);
      }
    }

    let elsevierAbstract = document.querySelector('.abstract.author');
    if (elsevierAbstract) {
      output.abstract = extractFullText(elsevierAbstract);
    }

    let imsHeader = document.querySelector('h2.main-title');
    if (imsHeader && /abstract/i.test(imsHeader.innerText)) {
      let parent = imsHeader.parentElement;
      if (parent) {
        let imsAbstractDiv = parent.querySelector('div');
        if (imsAbstractDiv) {
          output.abstract = Array.from(imsAbstractDiv.querySelectorAll('p'))
            .map(p => p.innerText.trim())
            .filter(t => t.length > 0)
            .join("\\n\\n");
        }
      }
    }
    if (!output.abstract) {
      let sectionAbstract = document.getElementById('abstract') || document.querySelector('section.abstract');
      if (sectionAbstract) {
        let inner = sectionAbstract.querySelector('.content, .abstract-text, .wrapper');
        output.abstract = extractFullText(inner || sectionAbstract);
      }
    }

    let abstractDiv = [...document.querySelectorAll('div, section')]
      .find(el => /abstract/i.test(el.className) || /abstract/i.test(el.id));
    if (abstractDiv && !output.abstract) {
      output.abstract = extractFullText(abstractDiv);
    }

    if (!output.abstract) {
      let metaDesc = document.querySelector('meta[name="description"]');
      if (metaDesc) output.abstract = metaDesc.content.trim();
    }
  }

  // ====== GRAPHICAL ABSTRACT ======
  if (${graphicalAbstract ? "true" : "false"}) {
    function isGraphicalAbstract(el) {
      if (!el) return false;
      if (/(graphical\\s*abstract|ga)/i.test(el.alt || el.title || el.dataset.caption || '')) return true;
      if (/(graphical\\s*abstract|ga|graphic|figure|f[0-9]|abspara)/i.test(el.parentElement?.className || el.parentElement?.id || '')) return true;
      return false;
    }

    let elsevierLrgLink = document.querySelector('a.download-link[href*="_lrg.jpg"], a.download-link[href*="_lrg.png"]');
    if (elsevierLrgLink?.href) output.graphicalAbstract = elsevierLrgLink.href;

    if (!output.graphicalAbstract) {
      let cellPressLink = document.querySelector('a.icon-full-screen[href*="_lrg.jpg"], a.icon-full-screen[href*="_lrg.png"]');
      if (cellPressLink?.href && isGraphicalAbstract(cellPressLink.parentElement)) output.graphicalAbstract = cellPressLink.href;
    }

    if (!output.graphicalAbstract) {
      let copernicusImg = document.querySelector('img[data-web][src*="thumb"]');
      if (copernicusImg?.getAttribute('data-web')?.includes('avatar')) output.graphicalAbstract = copernicusImg.getAttribute('data-web');
    }

    if (!output.graphicalAbstract) {
      let wileyGA = document.querySelector('#abstract-graphical-en img.figure__image');
      if (wileyGA?.getAttribute('data-lg-src')) output.graphicalAbstract = wileyGA.getAttribute('data-lg-src');
      else if (wileyGA?.src) output.graphicalAbstract = wileyGA.src;
    }

    if (!output.graphicalAbstract) {
      let gaLink = document.querySelector('a[href*="ga1_lrg"], a[href*="large"], a[href*="full"], a[title*="abstract"]');
      if (gaLink?.href && isGraphicalAbstract(gaLink.parentElement)) output.graphicalAbstract = gaLink.href;
    }

    if (!output.graphicalAbstract) {
      let figureSelectors = document.querySelectorAll('img.figure-img, img.graphic-abstract, img[src*="full"], img[src*="large"], img[alt*="abstract"]');
      for (let img of figureSelectors) {
        if (img.src && !/(thumb|small|mini)/i.test(img.src) && isGraphicalAbstract(img)) {
          output.graphicalAbstract = img.src.replace(/_w\\d+/, '_w1000').replace(/_s\\d+/, '_s1000');
          break;
        }
      }
    }

    // -- LAST RESORT --
    if (!output.graphicalAbstract) {
      let headingSelectors = ["h2", "h3", "h4", "figure"];
      for (let sel of headingSelectors) {
        let headings = document.querySelectorAll(sel);
        for (let h of headings) {
          if (/graphical\\s*abstract/i.test(h.innerText || "")) {
            let img = h.querySelector("img") || h.nextElementSibling?.querySelector("img");
            if (img?.src && !/(thumb|small|mini)/i.test(img.src)) {
              output.graphicalAbstract = img.src.replace(/_w\\d+/, '_w1000').replace(/_s\\d+/, '_s1000');
              break;
            }
          }
        }
        if (output.graphicalAbstract) break;
      }
    }
  }

  return output;
})();
""");

            Map<String, String?> result = {};
            if (rawResult is Map) {
              result = rawResult.map(
                  (key, value) => MapEntry(key.toString(), value?.toString()));
            }

            String? graphicalAbstractUrl = result['graphicalAbstract'];
            if (graphicalAbstractUrl != null) {
              if (graphicalAbstractUrl.startsWith("//")) {
                graphicalAbstractUrl = "https:$graphicalAbstractUrl";
              } else if (graphicalAbstractUrl.startsWith("/")) {
                final uri = Uri.parse(loadedUrl!.toString());
                graphicalAbstractUrl =
                    "${uri.scheme}://${uri.host}$graphicalAbstractUrl";
              }
              result['graphicalUrl'] = graphicalAbstractUrl;
              result.remove('graphicalAbstract');
            }

            if (result['abstract'] != null) {
              result['abstract'] = cleanAbstract(result['abstract']!);
            }

            _completer.complete(result);
          } catch (e, stackTrace) {
            logger.severe('Scraping failed.', e, stackTrace);
            _completer.completeError(e);
          } finally {
            if (!Platform.isWindows) {
              await InAppWebViewController.clearAllCache();
            }
            headlessWebView?.dispose();
          }
        });

    await headlessWebView.run();
    return _completer.future;
  }

  Future<String?> scrapeGraphicalAbstract(String url) async {
    final result = await scrapeAbstractAndGraphical(url,
        textAbstract: false, graphicalAbstract: true);
    return result['graphicalUrl'];
  }
}
