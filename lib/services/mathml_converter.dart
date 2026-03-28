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
    '{': r'\{',
    '}': r'\}',
  };

  String convert(String raw) {
    try {
      final cleaned = raw
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
          '<root xmlns:mml="http://www.w3.org/1998/Math/MathML">$cleaned</root>';
      final document = XmlDocument.parse(wrapped);
      String result = _convertChildren(document.rootElement.children).trim();

      return result
          .replaceAll('\$ \$', '')
          .replaceAll('\$\$', '')
          .replaceAll(RegExp(r' +'), ' ');
    } catch (e, stackTrace) {
      logger.warning('Unable to convert MathML to Latex.', e, stackTrace);
      return raw;
    }
  }

  String _convertChildren(List<XmlNode> nodes) {
    final buffer = StringBuffer();
    for (var node in nodes) {
      if (node is XmlText) {
        buffer.write(_applyMapping(node.value.replaceAll(RegExp(r'\s+'), ' ')));
      } else if (node is XmlElement) {
        if (node.name.local == 'math') {
          String mathContent = _convertNode(node).trim();
          if (mathContent.startsWith('_') || mathContent.startsWith('^')) {
            String current = buffer.toString();
            final match =
                RegExp(r'([a-zA-Z0-9\(\)\[\]]+) ?$').firstMatch(current);
            if (match != null) {
              String base = match.group(1)!;
              String precedingText =
                  current.substring(0, current.length - match.group(0)!.length);
              buffer.clear();
              buffer.write(precedingText);
              buffer.write('\$$base$mathContent\$');
            } else {
              buffer.write('\$$mathContent\$');
            }
          } else {
            if (buffer.isNotEmpty && !buffer.toString().endsWith(' ')) {
              buffer.write(' ');
            }
            buffer.write('\$$mathContent\$');
          }
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
          if (tag == 'munder' && (sub.contains(r'\bar') || sub.contains('‾'))) {
            return r'\underline{' + base + '}';
          }
          return '${base}_{$sub}';

        case 'msup':
        case 'mover':
          if (elements.isEmpty) return '';
          final base = _convertNode(elements[0]);
          final sup = elements.length > 1 ? _convertNode(elements[1]) : '';
          if (tag == 'mover' && (sup.contains(r'\bar') || sup.contains('‾'))) {
            return r'\overline{' + base + '}';
          }
          return '${base}^{$sup}';

        case 'msubsup':
        case 'munderover':
          if (elements.isEmpty) return '';
          return '${_convertNode(elements[0])}_{${elements.length > 1 ? _convertNode(elements[1]) : ""}}^{${elements.length > 2 ? _convertNode(elements[2]) : ""}}';

        case 'msqrt':
          return '\\sqrt{${processChildren()}}';
        case 'mroot':
          if (elements.length < 2) return '\\sqrt{${processChildren()}}';
          return '\\sqrt[${_convertNode(elements[1])}]{${_convertNode(elements[0])}}';
        case 'mtable':
          return '\\begin{matrix}${processChildren()}\\end{matrix}';
        case 'mtr':
          return processChildren() + r' \\ ';
        case 'mtd':
          return processChildren() + ' & ';
        case 'mfrac':
          return '\\frac{${elements.isNotEmpty ? _convertNode(elements[0]) : ""}}{${elements.length > 1 ? _convertNode(elements[1]) : ""}}';
        case 'mfenced':
          return '${node.getAttribute('open') ?? '('}${processChildren()}${node.getAttribute('close') ?? ')'}';
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
