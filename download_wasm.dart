import 'dart:io';

Future<void> main() async {
  print('Downloading sqlite3.wasm...');
  final wasmReq = await HttpClient().getUrl(Uri.parse('https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.4.6/sqlite3.wasm'));
  final wasmRes = await wasmReq.close();
  final wasmFile = File('web/sqlite3.wasm');
  await wasmRes.pipe(wasmFile.openWrite());
  
  print('Done! Valid sqlite3.wasm downloaded to web folder.');
}
