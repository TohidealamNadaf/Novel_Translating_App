import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://sport.thepaperbooks.com/read/297656/?13877674';
  final response = await http.get(Uri.parse(url), headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  });
  
  File('scrape_test.html').writeAsStringSync(response.body);
  print('Done! Status: ${response.statusCode}');
}
