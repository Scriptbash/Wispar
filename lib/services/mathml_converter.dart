import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

// Converts MathML to latex equations so that they can be rendered with Latext
class MathmlToLatexConverter {
  String convert(String raw) {
    try {
      final wrapped = '<root>$raw</root>';
      final document = XmlDocument.parse(wrapped);
      return _convertChildren(document.rootElement.children);
    } catch (e) {
      debugPrint("Unable to convert MathML: ${e}");
      return raw;
    }
  }

  String _convertChildren(List<XmlNode> nodes) {
    final buffer = StringBuffer();
    final formulaBuffer = StringBuffer();
    bool insideFormula = false;

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      if (node is XmlText) {
        final text = node.value;
        final trimmed = text.trimRight();

        final isChemicalSymbol =
            RegExp(r'^[A-Z][a-z]?$').hasMatch(trimmed.trim());

        if (isChemicalSymbol) {
          // Start formula buffering if not already
          if (!insideFormula) {
            insideFormula = true;
            formulaBuffer.clear();
          }
          formulaBuffer.write(trimmed.trim());
        } else {
          // Flush formula if any
          if (insideFormula) {
            buffer.write('\$${formulaBuffer.toString()}\$');
            formulaBuffer.clear();
            insideFormula = false;
          }
          buffer.write(trimmed); // regular text
        }
      } else if (node is XmlElement && node.name.local == 'math') {
        final mathContent = _convertChildren(node.children);
        if (!insideFormula) {
          insideFormula = true;
          formulaBuffer.clear();
        }
        formulaBuffer.write(mathContent);

        // Look ahead, if next is not another <math>, flush now
        final next = i + 1 < nodes.length ? nodes[i + 1] : null;
        final isNextMath = next is XmlElement && next.name.local == 'math';
        final isNextChemText = next is XmlText &&
            RegExp(r'^[A-Z][a-z]?$').hasMatch(next.value.trim());

        if (!isNextMath && !isNextChemText) {
          buffer.write('\$${formulaBuffer.toString()}\$');
          formulaBuffer.clear();
          insideFormula = false;
        }
      } else {
        if (insideFormula) {
          buffer.write('\$${formulaBuffer.toString()}\$');
          formulaBuffer.clear();
          insideFormula = false;
        }
        buffer.write(_convertNode(node));
      }
    }

    // Final flush
    if (insideFormula && formulaBuffer.isNotEmpty) {
      buffer.write('\$${formulaBuffer.toString()}\$');
    }

    return buffer.toString();
  }

  String _convertNode(XmlNode node) {
    if (node is XmlText) {
      return node.value;
    }

    if (node is XmlElement) {
      final tag = node.name.local;

      // Detect full <math> tag
      if (tag == 'math') {
        final latex = _convertChildren(node.children);
        return '\$$latex\$'; // wrap with dollar signs for Latext
      }

      // Handle MathML elements inside <math>
      switch (tag) {
        case 'mi':
        case 'mn':
        case 'mo':
          return node.innerText;
        case 'msup':
          final base =
              node.children.length > 0 ? _convertNode(node.children[0]) : '';
          final sup =
              node.children.length > 1 ? _convertNode(node.children[1]) : '';
          return '$base^{$sup}';
        case 'msub':
          final base =
              node.children.length > 0 ? _convertNode(node.children[0]) : '';

          final sub =
              node.children.length > 1 ? _convertNode(node.children[1]) : '';
          return '${base}_{$sub}';
        case 'mfrac':
          final numerator =
              node.children.length > 0 ? _convertNode(node.children[0]) : '';
          final denominator =
              node.children.length > 1 ? _convertNode(node.children[1]) : '';
          return '\\frac{$numerator}{$denominator}';
        case 'msqrt':
          return '\\sqrt{${_convertChildren(node.children)}}';
        case 'mrow':
          return _convertChildren(node.children);
        default:
          return _convertChildren(node.children);
      }
    }
    return '';
  }
}
