import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://sport.thepaperbooks.com/read/297656/?13877674';
  final client = http.Client();
  try {
    final response = await client.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Referer': 'https://sport.thepaperbooks.com',
      },
    ).timeout(const Duration(seconds: 30));
    
    print('Status: ${response.statusCode}');
    File('debug_sport.html').writeAsStringSync(response.body);
    
    // Print all text in body
    final body = response.body;
    if (body.contains('Chapter List') || body.contains('Chapter list')) {
      print('FOUND "Chapter List"');
    }
  } finally {
    client.close();
  }
}
