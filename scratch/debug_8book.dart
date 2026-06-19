import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  // Try a real 8book.com reading URL
  final urls = [
    'https://www.8book.com/read/59678/',
    'https://8book.com/read/59678/',
  ];
  
  for (final url in urls) {
    print('\n--- Fetching: $url ---');
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 30));
      
      print('Status: ${response.statusCode}');
      print('Content length: ${response.body.length}');
      
      final titleMatch = RegExp(r'<title>(.*?)</title>', dotAll: true).firstMatch(response.body);
      print('Title: ${titleMatch?.group(1)?.trim()}');
      
      // Parse with html parser
      final doc = html_parser.parse(response.body);
      
      // Check all common selectors
      final selectors = [
        '.txtnav', '#content', '#TextContent', '.readcontent',
        '.chapter_content', '.post-content', '.entry-content',
        '#nr_content', '.book_content', '.article-content',
        '.novel-content', '#chaptercontent', '.chapter-text',
        '#booktext', '.bookcontent', '#chapterContent',
        '.txt_cont', '#nr1', '.nr_txt', '.contentbox',
        '#contentbox', '.text-content', '#text-content',
      ];
      
      for (final sel in selectors) {
        try {
          final el = doc.querySelector(sel);
          if (el != null) {
            final text = el.text.trim();
            print('FOUND $sel -> ${text.length} chars: "${text.substring(0, text.length > 100 ? 100 : text.length)}..."');
          }
        } catch (_) {}
      }
      
      // Also check what the page actually contains
      if (response.body.contains('Chapter List') || response.body.contains('章節列表') || response.body.contains('章节列表')) {
        print('WARNING: This is a chapter list page, not a chapter content page');
      }
      
      // Check for any divs with significant text
      final divs = doc.querySelectorAll('div');
      var maxLen = 0;
      String? maxId;
      String? maxClass;
      for (final div in divs) {
        final text = div.text.trim();
        if (text.length > maxLen) {
          maxLen = text.length;
          maxId = div.attributes['id'];
          maxClass = div.attributes['class'];
        }
      }
      print('Longest div: id=$maxId class=$maxClass length=$maxLen');
      
      // Save HTML for analysis
      File('debug_8book.html').writeAsStringSync(response.body);
      print('Saved to debug_8book.html');
      
    } finally {
      client.close();
    }
  }
}
