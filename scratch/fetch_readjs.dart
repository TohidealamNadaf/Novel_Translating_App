import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://8book.com/js/read.js';
  final client = http.Client();
  try {
    final response = await client.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36',
      },
    );
    print('Status: ${response.statusCode}');
    File('scratch/read.js').writeAsStringSync(response.body);
    print('Saved to scratch/read.js');
  } finally {
    client.close();
  }
}
