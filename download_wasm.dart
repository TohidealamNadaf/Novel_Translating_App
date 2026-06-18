import 'dart:io';

Future<void> main() async {
  print('Downloading sqlite3.wasm...');
  final wasmReq = await HttpClient().getUrl(Uri.parse('https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.4.6/sqlite3.wasm'));
  final wasmRes = await wasmReq.close();
  final wasmFile = File('web/sqlite3.wasm');
  await wasmRes.pipe(wasmFile.openWrite());
  
  print('Downloading sqflite_sw.js from tekartik repo...');
  final swReq = await HttpClient().getUrl(Uri.parse('https://raw.githubusercontent.com/tekartik/sqflite/master/packages/sqflite_common_ffi_web/lib/assets/sqflite_sw.js'));
  final swRes = await swReq.close();
  final swFile = File('web/sqflite_sw.js');
  await swRes.pipe(swFile.openWrite());
  
  print('Done! Files downloaded to web folder.');
}
