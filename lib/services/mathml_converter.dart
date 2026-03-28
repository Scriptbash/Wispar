import 'package:xml/xml.dart';
import 'package:wispar/services/logs_helper.dart';

class MathmlToLatexConverter {
  final logger = LogsService().logger;

  final _specialChars = {
    'α': r'\alpha',
    'β': r'\beta',
    'γ': r'\gamma',
    'δ': r'\delta',
    'Δ': r'\Delta',
    'λ': r'\lambda',
    'μ': r'\mu',
    'π': r'\pi',
    'σ': r'\sigma',
    'Ω': r'\Omega',
    'τ': r'\tau',
    'ν': r'\nu',
    'θ': r'\theta',
    'φ': r'\phi',
    'ψ': r'\psi',
    'η': r'\eta',
    '±': r'\pm',
    '→': r'\to',
    '∞': r'\infty',
    '≈': r'\approx',
    '≠': r'\neq',
    '×': r'\times',
    '·': r'\cdot',
    '°': r'^\circ',
    '−': '-',
    '—': '-',
    '‾': r'\bar',
    '∘': r'\circ',
    '⁺': r'^+',
    '⁻': '^-',
    '⁰': r'^0',
  };

  String convert(String raw) {
    try {
      final cleaned = raw
          .replaceAll('mml:', '')
          .replaceAll('&InvisibleTimes;', '')
          .replaceAll('&it;', '')
          .replaceAll('&sdot;', '·')
          .replaceAll('\u2062', '')
          .replaceAll('\u2212', '-')
          .replaceAll('\u203e', r'\bar')
          .replaceAll('\u2218', r'\circ');

      final wrapped = '<root>$cleaned</root>';
      final document = XmlDocument.parse(wrapped);

      return _convertChildren(document.rootElement.children).trim();
    } catch (e, stackTrace) {
      logger.warning('Unable to convert MathML to Latex.', e, stackTrace);
      return raw;
    }
  }

  String _convertChildren(List<XmlNode> nodes) {
    final buffer = StringBuffer();

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      if (node is XmlText) {
        buffer.write(_applyMapping(node.value));
      } else if (node is XmlElement) {
        final tag = node.name.local;
        if (tag == 'math') {
          String mathContent = _convertNode(node).trim();

          if (mathContent.startsWith('_') || mathContent.startsWith('^')) {
            String current = buffer.toString().trimRight();
            final match =
                RegExp(r'([a-zA-Z0-9\(\)\[\]]+)$').firstMatch(current);

            buffer.clear();
            if (match != null) {
              String base = match.group(0)!;
              String precedingText =
                  current.substring(0, current.length - base.length);

              if (precedingText.trimRight().endsWith(r'$')) {
                precedingText = precedingText.trimRight();
                precedingText =
                    precedingText.substring(0, precedingText.length - 1);
                buffer.write(precedingText);
                buffer.write('$base$mathContent\$');
              } else {
                buffer.write(precedingText);
                buffer.write('\$$base$mathContent\$');
              }
            } else {
              buffer.write(current);
              buffer.write('\$$mathContent\$');
            }
          } else {
            if (buffer.isNotEmpty && !buffer.toString().endsWith(' ')) {
              buffer.write(' ');
            }
            buffer.write('\$$mathContent\$');
          }
        } else {
          buffer.write(_convertNode(node));
        }
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _convertNode(XmlNode node) {
    if (node is XmlText) return _applyMapping(node.value);

    if (node is XmlElement) {
      final tag = node.name.local;
      switch (tag) {
        case 'mi':
        case 'mn':
        case 'mo':
        case 'mtext':
          return _applyMapping(node.innerText.trim());

        case 'math':
        case 'mrow':
        case 'mstyle':
          return node.children.map(_convertNode).join('');

        case 'msub':
          final children = node.children.whereType<XmlElement>().toList();
          if (children.isEmpty) return '';
          final base = _convertNode(children[0]).trim();
          final sub =
              children.length > 1 ? _convertNode(children[1]).trim() : '';
          return base.isEmpty ? '_{$sub}' : '{$base}_{$sub}';

        case 'msup':
          final children = node.children.whereType<XmlElement>().toList();
          if (children.isEmpty) return '';
          final base = _convertNode(children[0]).trim();
          final sup =
              children.length > 1 ? _convertNode(children[1]).trim() : '';
          return base.isEmpty ? '^{$sup}' : '{$base}^{$sup}';

        case 'msubsup':
          final children = node.children.whereType<XmlElement>().toList();
          if (children.isEmpty) return '';
          final base = _convertNode(children[0]).trim();
          final sub =
              children.length > 1 ? _convertNode(children[1]).trim() : '';
          final sup =
              children.length > 2 ? _convertNode(children[2]).trim() : '';
          return '{$base}_{$sub}^{$sup}';

        case 'mover':
          final children = node.children.whereType<XmlElement>().toList();
          if (children.isEmpty) return '';
          final base = _convertNode(children[0]).trim();
          final over =
              children.length > 1 ? _convertNode(children[1]).trim() : '';
          if (over == r'\bar' || over == '‾') return '\\bar{$base}';
          if (over == r'\vec' || over == '→') return '\\vec{$base}';
          return '\\overset{$over}{$base}';

        case 'munder':
          final children = node.children.whereType<XmlElement>().toList();
          if (children.isEmpty) return '';
          final base = _convertNode(children[0]).trim();
          final under =
              children.length > 1 ? _convertNode(children[1]).trim() : '';
          return '\\underset{$under}{$base}';

        case 'mfrac':
          final children = node.children.whereType<XmlElement>().toList();
          final num =
              children.isNotEmpty ? _convertNode(children[0]).trim() : '';
          final den =
              children.length > 1 ? _convertNode(children[1]).trim() : '';
          return '\\frac{$num}{$den}';

        case 'mfenced':
          final open = node.getAttribute('open') ?? '(';
          final close = node.getAttribute('close') ?? ')';
          final content = node.children.map(_convertNode).join(', ');
          return '$open$content$close';

        default:
          return node.children.map(_convertNode).join('');
      }
    }
    return '';
  }

  String _applyMapping(String text) {
    String result = text;
    _specialChars.forEach((unicode, latex) {
      result = result.replaceAll(unicode, latex);
    });
    return result;
  }
}
