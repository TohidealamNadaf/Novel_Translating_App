import 'dart:io';

void main() async {
  final url = 'https://corsproxy.io/?https%3A%2F%2Fsport.thepaperbooks.com%2Fread%2F297656%2F%3F13877674';
  
  final httpClient = HttpClient();
  try {
    final request = await httpClient.getUrl(Uri.parse(url));
    request.headers.add('Origin', 'http://localhost:8080');
    final response = await request.close();
    final body = await response.transform(SystemEncoding().decoder).join();
    print('Status: ${response.statusCode}');
    print('Body: $body');
  } catch (e) {
    print('Error: $e');
  }
}
