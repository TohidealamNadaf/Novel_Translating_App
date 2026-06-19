import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final req = http.Request('GET', Uri.parse('https://sport.thepaperbooks.com/read/297656/?13877674'))..followRedirects = false;
  req.headers['User-Agent'] = 'Mozilla/5.0';
  final res = await req.send();
  print('Status: ${res.statusCode}');
  print('Location: ${res.headers['location']}');
  
  if (res.statusCode == 200) {
     final body = await res.stream.bytesToString();
     print(body.substring(0, 300));
  }
}
