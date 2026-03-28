import 'package:xml/xml.dart';
import 'package:wispar/services/logs_helper.dart';

class MathmlToLatexConverter {
  final logger = LogsService().logger;

  final _functionNames = {
    'sin': r'\sin ',
    'cos': r'\cos ',
    'tan': r'\tan ',
    'log': r'\log ',
    'ln': r'\ln ',
    'lim': r'\lim ',
    'exp': r'\exp ',
    'min': r'\min ',
    'max': r'\max ',
    'sinh': r'\sinh ',
    'cosh': r'\cosh ',
    'tanh': r'\tanh ',
  };

  final _specialChars = {
    'α': r'\alpha ',
    'β': r'\beta ',
    'γ': r'\gamma ',
    'δ': r'\delta ',
    'Δ': r'\Delta ',
    'λ': r'\lambda ',
    'μ': r'\mu ',
    'π': r'\pi ',
    'σ': r'\sigma ',
    'Ω': r'\Omega ',
    'τ': r'\tau ',
    'ν': r'\nu ',
    'θ': r'\theta ',
    'φ': r'\phi ',
    'ψ': r'\psi ',
    'η': r'\eta ',
    '±': r'\pm ',
    '→': r'\to ',
    '∞': r'\infty ',
    '≈': r'\approx ',
    '≠': r'\neq ',
    '×': r'\times ',
    '·': r'\cdot ',
    '°': r'^\circ ',
    '−': '-',
    '—': '-',
    '‾': r'\bar',
    '∘': r'\circ ',
    '⁺': r'^+',
    '⁻': '^-',
    '⁰': r'^0',
    '⊂': r'\subset ',
    '÷': '--',
  };

  String convert(String raw) {
    try {
      final cleaned = raw
          .replaceAllMapped(RegExp(r'\$\$(.*?)\$\$', dotAll: true),
              (m) => '\$${m.group(1)}\$')
          .replaceAll('\u00A0', ' ')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&InvisibleTimes;', '')
          .replaceAll('&it;', '')
          .replaceAll('&sdot;', '·')
          .replaceAll('\u2062', '')
          .replaceAll('\u2212', '-')
          .replaceAll('\u203e', r'\bar')
          .replaceAll('\u2218', r'\circ ');

      final wrapped =
          '<root xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:jats="http://www.ncbi.nlm.nih.gov/JATS1.2">$cleaned</root>';
      final document = XmlDocument.parse(wrapped);

      String result = _convertChildren(document.rootElement.children).trim();

      return result
          .replaceAllMapped(
              RegExp(r'([a-zA-Z0-9]+)\s*\$(\{\})?(_{.*?}|\^{.*?})\$'),
              (match) => '\$' + match.group(1)! + match.group(3)! + '\$')
          .replaceAllMapped(RegExp(r'\$(\{\})?(_{.*?}|\^{.*?})\$'),
              (match) => '\${}' + match.group(2)! + '\$')
          .replaceAll('\$\$', '')
          .replaceAll(RegExp(r'\$\s+\$'), ' ')
          .replaceAll(RegExp(r'\$+\$'), '\$')
          .replaceAll(RegExp(r' +'), ' ')
          .trim();
    } catch (e, stackTrace) {
      logger.warning('Unable to convert MathML to Latex.', e, stackTrace);
      return raw;
    }
  }

  String _convertChildren(List<XmlNode> nodes) {
    final buffer = StringBuffer();
    for (var node in nodes) {
      if (node is XmlText) {
        String text = node.value.replaceAll(RegExp(r'\s+'), ' ');

        String processed = text.splitMapJoin(
          RegExp(r'\$.+?\$'),
          onMatch: (m) => m.group(0)!,
          onNonMatch: (n) {
            String mapped = _applyMapping(n);

            return mapped.splitMapJoin(
              RegExp(r'\\[a-zA-Z]+(?:\s*\{[^{}]*\})*'),
              onMatch: (m) => '\$${m.group(0)!.trim()}\$',
              onNonMatch: (n2) => n2,
            );
          },
        );
        buffer.write(processed);
      } else if (node is XmlElement) {
        final localName = node.name.local;

        if (localName == 'alternatives') {
          final texNode = node.children.whereType<XmlElement>().firstWhere(
                (e) => e.name.local == 'tex-math',
                orElse: () => XmlElement(XmlName('empty')),
              );
          if (texNode.name.local != 'empty') {
            String tex = texNode.innerText
                .replaceAll('\$\$', '')
                .replaceAll('\$', '')
                .trim();
            buffer.write('\$$tex\$');
            continue;
          }
        }

        if (localName == 'math') {
          String mathContent = _convertNode(node).trim();
          if (mathContent.isEmpty) continue;
          buffer.write('\$$mathContent\$');
        } else if (localName == 'italic') {
          String content =
              _convertChildren(node.children).trim().replaceAll('\$', '');
          if (content.isNotEmpty) buffer.write('\$$content\$');
        } else if (localName == 'sup') {
          String content =
              _convertChildren(node.children).trim().replaceAll('\$', '');
          if (content.isNotEmpty) buffer.write('\$^{$content\}\$');
        } else if (localName == 'sub') {
          String content =
              _convertChildren(node.children).trim().replaceAll('\$', '');
          if (content.isNotEmpty) buffer.write('\$_{$content\}\$');
        } else if (localName == 'sc') {
          buffer.write(_convertChildren(node.children).trim().toUpperCase());
        } else {
          buffer.write(_convertChildren(node.children));
        }
      }
    }
    return buffer.toString();
  }

  String _convertNode(XmlNode node) {
    if (node is XmlText) return _applyMapping(node.value.trim());

    if (node is XmlElement) {
      final tag = node.name.local;
      final variant = node.getAttribute('mathvariant');
      final elements = node.children.whereType<XmlElement>().toList();

      String processChildren() => node.children
          .where((n) => n is! XmlText || n.value.trim().isNotEmpty)
          .map(_convertNode)
          .join('');

      switch (tag) {
        case 'mi':
        case 'mn':
        case 'mo':
        case 'mtext':
          String content = node.innerText.trim();
          if (_functionNames.containsKey(content)) {
            return _functionNames[content]!;
          }
          content = _applyMapping(content);
          if (content.isEmpty) return '';
          if (variant == 'fraktur') return r'\mathfrak{' + content + '}';
          if (variant == 'script') return r'\mathcal{' + content + '}';
          if (variant == 'bold') return r'\mathbf{' + content + '}';
          return content;

        case 'msub':
        case 'munder':
          if (elements.isEmpty) return '';
          final base = _convertNode(elements[0]);
          final sub = elements.length > 1 ? _convertNode(elements[1]) : '';
          return '${base.isEmpty ? '{}' : base}_{$sub}';

        case 'msup':
          if (elements.isEmpty) return '';
          final base = _convertNode(elements[0]);
          final sup = elements.length > 1 ? _convertNode(elements[1]) : '';
          return '${base.isEmpty ? '{}' : base}^{$sup}';

        case 'mover':
          if (elements.isEmpty) return '';
          final base = _convertNode(elements[0]);
          final over =
              elements.length > 1 ? _convertNode(elements[1]).trim() : '';

          if (over == r'\bar') return r'\bar{' + base + '}';
          if (over == r'\to') {
            return r'\vec{' + base + '}';
          }
          if (over == '^' || over == r'\hat') return r'\hat{' + base + '}';
          if (over == '~' || over == r'\tilde') return r'\tilde{' + base + '}';

          return r'\overline{' + base + '}';

        case 'msubsup':
        case 'munderover':
          if (elements.isEmpty) return '';
          final base = _convertNode(elements[0]);
          final sub = elements.length > 1 ? _convertNode(elements[1]) : '';
          final sup = elements.length > 2 ? _convertNode(elements[2]) : '';
          return '${base.isEmpty ? '{}' : base}_{$sub}^{$sup}';

        case 'mfrac':
          return '\\frac{${elements.isNotEmpty ? _convertNode(elements[0]) : ""}}{${elements.length > 1 ? _convertNode(elements[1]) : ""}}';

        case 'mfenced':
          return '(${processChildren()})';

        case 'msqrt':
          return '\\sqrt{${processChildren()}}';

        default:
          return processChildren();
      }
    }
    return '';
  }

  String _applyMapping(String text) {
    String result = text;
    _specialChars.forEach(
        (unicode, latex) => result = result.replaceAll(unicode, latex));
    return result;
  }
}
