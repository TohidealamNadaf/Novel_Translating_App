import 'dart:io';

void main() {
  final html = File('debug_sport.html').readAsStringSync();
  
  // Extract itemid
  final itemIdMatch = RegExp(r'<meta name="itemid" content="(\d+)"').firstMatch(html);
  final itemId = itemIdMatch?.group(1);
  print('itemId: $itemId');
  
  // Look for the big block of variable definitions.
  // It usually looks like: var ab_4w9o=2;var po24547=3;var d80c1178="第1章..."
  
  // Find all variable assignments of integer values: var a=1;
  // And the chapter arrays: var b="...";
  
  // The variables used in the formula are:
  // 1. A multiplier (po24547 = 3)
  // 2. A modulo (h8h3685rb = 100)
  // 3. A substring length (tu8q348h3 = 5)
  // 4. The array of chapter IDs (q77upv1 = "13877673,...".split(','))
  
  // If we find the unescape call, it might tell us exactly which variables are used!
  final ajaxMatch = RegExp(r'\$\.get\(unescape\((.*?)\),function').firstMatch(html);
  if (ajaxMatch != null) {
    print('Ajax call found: ${ajaxMatch.group(1)}');
  }
  
  // Since we only need `txt/{itemid / 100000}/{itemid}/{chapterid}{hash}.html`
  // We can just extract the last long string from the HTML, which is the hash source!
  // The chapter ID array ends with a giant number string.
  final q77Match = RegExp(r'var [a-zA-Z0-9_]+="(\d+(?:,\d+)*,(\d{100,}))"\.split\(').firstMatch(html);
  if (q77Match != null) {
    final lastString = q77Match.group(2);
    print('Found hash source string of length ${lastString?.length}');
    
    // Now we need the multiplier, modulo, and length.
    // They are often hardcoded in the unescape line or nearby.
    // substr(c5q0__2 * po24547 % h8h3685rb, tu8q348h3)
    // Let's find substr(.*? \w+ % \w+, \w+)
    final substrMatch = RegExp(r'\.substr\([a-zA-Z0-9_]+ \* ([a-zA-Z0-9_]+) % ([a-zA-Z0-9_]+),\s*([a-zA-Z0-9_]+)\)').firstMatch(html);
    if (substrMatch != null) {
      final multVar = substrMatch.group(1);
      final modVar = substrMatch.group(2);
      final lenVar = substrMatch.group(3);
      print('MultVar: $multVar, ModVar: $modVar, LenVar: $lenVar');
      
      // Now extract their values
      final multVal = RegExp('var $multVar=(\\d+);').firstMatch(html)?.group(1);
      final modVal = RegExp('var $modVar=(\\d+);').firstMatch(html)?.group(1);
      final lenVal = RegExp('var $lenVar=(\\d+);').firstMatch(html)?.group(1);
      
      print('Mult: $multVal, Mod: $modVal, Len: $lenVal');
    }
  }
}
