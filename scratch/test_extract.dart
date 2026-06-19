import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

void main() {
  final html = File('debug_sport.html').readAsStringSync();
  final doc = html_parser.parse(html);
  
  // Re-implement _extractGeneric to see what it does
  const common = [
    'article',
    '.chapter-content',
    '#chapter-content',
    '.read-content',
    '.reading-content',
    '.novel-content',
    '.post-content',
    '.entry-content',
    '#nr_content',
    '.book_content',
    '.article-content',
    '#content',
    '.content',
  ];
  
  void _strip(Element el, List<String> selectors) {
    for (final sel in selectors) {
      try {
        el.querySelectorAll(sel).forEach((e) => e.remove());
      } catch (_) {}
    }
  }

  void _stripNoise(Element el) {
    _strip(el, const [
      'script', 'style', 'nav', 'footer', 'header', 'iframe', 'noscript',
      '.ads', '.ad', '.advertisement', '.social-share', '.comments', '.sidebar',
    ]);
  }

  String _textFrom(Element el) {
    final raw = el.innerHtml
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?p[^>]*>', caseSensitive: false), '\n');
    final tempDoc = html_parser.parse(raw);
    return tempDoc.body?.text.trim() ?? '';
  }

  for (final sel in common) {
    try {
      final el = doc.querySelector(sel);
      if (el != null && el.text.trim().length > 200) {
        _stripNoise(el);
        print('Found via common $sel: ${_textFrom(el)}');
        return;
      }
    } catch (_) {}
  }

  Element? best;
  int bestLen = 0;
  for (final div in doc.querySelectorAll('div')) {
    final len = div.text.trim().length;
    if (len > bestLen) {
      bestLen = len;
      best = div;
    }
  }
  if (best != null && bestLen > 200) {
    print('Found via longest div length $bestLen (id=${best.id}, class=${best.className})');
    _stripNoise(best);
    print('Content: ${_textFrom(best)}');
    return;
  }

  final fallback = doc
      .querySelectorAll('p')
      .map((p) => p.text.trim())
      .where((t) => t.isNotEmpty)
      .join('\n\n');
      
  print('Fallback to p tags: $fallback');
}
