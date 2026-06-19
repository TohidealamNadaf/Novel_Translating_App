import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  // Test the sport.thepaperbooks.com URL from the user
  final url = 'https://sport.thepaperbooks.com/read/297656/?13877674';
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
    
    // Find the title
    final titleMatch = RegExp(r'<title>(.*?)</title>', dotAll: true).firstMatch(response.body);
    print('Title: ${titleMatch?.group(1)?.trim()}');
    
    // Check for common selectors
    final selectors = [
      '.txtnav', '#content', '#TextContent', '.readcontent',
      '.chapter_content', '.post-content', '.entry-content',
      '#nr_content', '.book_content', '.article-content',
      '.novel-content', '#chaptercontent', '.chapter-text',
      '#booktext', '.bookcontent', '#chapterContent',
      '.txt_cont', '#nr1', '.nr_txt',
    ];
    
    for (final sel in selectors) {
      // Simple check: does the class/id appear in the HTML?
      final found = response.body.contains(sel.replaceFirst('.', 'class="').replaceFirst('#', 'id="'));
      if (found) {
        print('FOUND selector: $sel');
      }
    }
    
    // Also look for Chapter List text
    if (response.body.contains('Chapter List')) {
      print('WARNING: Page contains "Chapter List" text');
    }
    
    // Find all links with text containing chapter info
    final linkPattern = RegExp(r'<a[^>]*href="([^"]*)"[^>]*>([^<]*章[^<]*)</a>');
    final matches = linkPattern.allMatches(response.body);
    print('\nChapter-like links found: ${matches.length}');
    for (final m in matches.take(5)) {
      print('  Link: ${m.group(1)} -> ${m.group(2)}');
    }
    
    // Write full HTML
    File('debug_scrape.html').writeAsStringSync(response.body);
    print('\nFull HTML written to debug_scrape.html (${response.body.length} bytes)');
    
  } finally {
    client.close();
  }
}
