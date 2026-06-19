import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  // Try different 8book.com URL patterns with a chapter ID 
  final urls = [
    'https://8book.com/read/59678/?13877674',
    'https://www.8book.com/readbook/59678/13877674.html',
    'https://www.8book.com/novel/59/59678/13877674.html',
    'https://8book.com/api/Fiction/GetContent?fictionId=59678&chapterId=13877674',
    'https://8book.com/api/Fiction/GetContent?bookId=59678&chapterId=13877674',
  ];
  
  final client = http.Client();
  try {
    for (final url in urls) {
      print('\n--- $url ---');
      try {
        final response = await client.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'text/html,application/json,*/*',
            'Accept-Language': 'zh-CN,zh;q=0.9',
            'Referer': 'https://8book.com/',
          },
        ).timeout(const Duration(seconds: 15));
        
        print('Status: ${response.statusCode}');
        print('Content-Type: ${response.headers['content-type']}');
        print('Body length: ${response.body.length}');
        
        // Check if it's JSON
        if (response.headers['content-type']?.contains('json') == true || response.body.trim().startsWith('{')) {
          print('JSON response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        } else {
          // Check title
          final titleMatch = RegExp(r'<title>(.*?)</title>', dotAll: true).firstMatch(response.body);
          print('Title: ${titleMatch?.group(1)?.trim()}');
          
          // Save it
          File('debug_8book_${urls.indexOf(url)}.html').writeAsStringSync(response.body);
          
          // Check for .txtnav or #content
          final doc = html_parser.parse(response.body);
          for (final sel in ['.txtnav', '#content', '#TextContent', '.readcontent', '#nr_content', '#chaptercontent', '.chapter_content', '.bookcontent', '#booktext']) {
            final el = doc.querySelector(sel);
            if (el != null) {
              final txt = el.text.trim();
              print('  Found $sel (${txt.length} chars): "${txt.substring(0, txt.length > 80 ? 80 : txt.length)}"');
            }
          }
        }
      } catch (e) {
        print('ERROR: $e');
      }
    }
  } finally {
    client.close();
  }
}
