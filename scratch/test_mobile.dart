import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final req = http.Request('GET', Uri.parse('https://sport.thepaperbooks.com/read/297656/?13877674'));
  req.headers['User-Agent'] = 'Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.162 Mobile Safari/537.36';
  req.headers['Accept-Language'] = 'zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7';
  req.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8';
  final res = await req.send();
  print('Status: ${res.statusCode}');
  
  if (res.statusCode == 200) {
     final body = await res.stream.bytesToString();
     File('scrape_test.html').writeAsStringSync(body);
     print('Wrote to scrape_test.html');
  }
}
