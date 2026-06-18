import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'dart:io';

void main() async {
  final url = 'https://sport.thepaperbooks.com/read/297656/?13877674';
  
  final request = await HttpClient().getUrl(Uri.parse(url));
  final response = await request.close();
  final html = await response.transform(SystemEncoding().decoder).join();
  
  final document = html_parser.parse(html);
  
  // Last resort: all <p> tags
  final paragraphs = document.querySelectorAll('p');
  final result = paragraphs.map((p) => p.text.trim()).where((t) => t.isNotEmpty).join('\n\n');
  print('P tags extracted length: ${result.length}');
  
  // Try longest div
  final divs = document.querySelectorAll('div');
  Element? longestDiv;
  int maxLength = 0;

  for (final div in divs) {
    final textLength = div.text.trim().length;
    if (textLength > maxLength) {
      maxLength = textLength;
      longestDiv = div;
    }
  }

  print('Longest div length: $maxLength');
  if (longestDiv != null && maxLength > 200) {
    _stripUnwantedElements(longestDiv);
    print('Longest div text after strip: ${_extractText(longestDiv).length}');
  }
}

void _stripUnwantedElements(Element element) {
  final selectorsToRemove = [
    'script', 'style', 'nav', 'footer', 'header', '.ads', '.ad', '.advertisement', 
    '.social-share', '.comments', '.sidebar', 'iframe', 'noscript'
  ];
  for (final selector in selectorsToRemove) {
    try {
      element.querySelectorAll(selector).forEach((e) => e.remove());
    } catch (_) {}
  }
}

String _extractText(Element element) {
  final paragraphs = element.querySelectorAll('p');
  if (paragraphs.isNotEmpty) {
    return paragraphs.map((p) => p.text.trim()).where((t) => t.isNotEmpty).join('\n\n');
  }
  final html = element.innerHtml;
  return html.replaceAll(RegExp(r'<br\s*/?>'), '\n').replaceAll(RegExp(r'<[^>]+>'), '').split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).join('\n\n');
}
