import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final lastEl = "397771644887644654965381691794719522279169826678362781292728984928822258499556593253292933155218681785712438165533684172";
  final c = 13877674;
  final p = 3;
  final h = 100;
  final t = 5;
  
  final idx = (c * p) % h;
  final hash = lastEl.substring(idx, idx + t);
  print('Hash: $hash');
  
  final url = 'https://sport.thepaperbooks.com/txt/2/297656/13877674$hash.html';
  print('URL: $url');
  
  final client = http.Client();
  try {
    final response = await client.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36',
      },
    );
    print('Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      File('scratch/chapter_text.html').writeAsStringSync(response.body);
      print('Saved to scratch/chapter_text.html');
      print(response.body.substring(0, 200));
    }
  } finally {
    client.close();
  }
}
