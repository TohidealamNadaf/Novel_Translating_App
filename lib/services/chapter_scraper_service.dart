import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:flutter/foundation.dart';
import 'package:gbk_codec/gbk_codec.dart';
import '../core/constants.dart';

/// Result of scraping a chapter
class ScrapedChapter {
  final String title;
  final String content; // plain text, paragraph-separated
  final String? nextChapterUrl;
  final String detectedLanguage;

  ScrapedChapter({
    required this.title,
    required this.content,
    this.nextChapterUrl,
    required this.detectedLanguage,
  });
}

/// Site-specific scraping profile
class SiteProfile {
  final String domain;
  final List<String> contentSelectors;
  final List<String> nextChapterSelectors;
  final List<String> titleSelectors;

  /// Extra noise selectors to strip from the content element
  final List<String> stripSelectors;

  /// 'gbk' or 'utf-8'
  final String charset;

  const SiteProfile({
    required this.domain,
    required this.contentSelectors,
    required this.nextChapterSelectors,
    required this.titleSelectors,
    this.stripSelectors = const [],
    this.charset = 'utf-8',
  });
}

class ChapterScraperService {
  // ─── Site profiles ───
  static const List<SiteProfile> _siteProfiles = [
    SiteProfile(
      domain: 'novelbin.me',
      contentSelectors: ['#chr-content', '.chr-c', '#chapter-content'],
      nextChapterSelectors: ['#next_chap', '.next_chap', 'a.next-chap'],
      titleSelectors: ['.chr-title', '.chapter-title', 'h2'],
    ),
    SiteProfile(
      domain: 'novelbin.net',
      contentSelectors: ['#chr-content', '.chr-c', '#chapter-content'],
      nextChapterSelectors: ['#next_chap', '.next_chap', 'a.next-chap'],
      titleSelectors: ['.chr-title', '.chapter-title', 'h2'],
    ),
    SiteProfile(
      domain: 'readnovelfull.com',
      contentSelectors: ['#chr-content', '#chapter-content'],
      nextChapterSelectors: ['#next_chap', '.next-chap'],
      titleSelectors: ['.chapter-title', 'h2', '.chr-title'],
    ),
    SiteProfile(
      domain: 'readnovelfull.me',
      contentSelectors: ['#chr-content', '#chapter-content'],
      nextChapterSelectors: ['#next_chap', '.next-chap'],
      titleSelectors: ['.chapter-title', 'h2'],
    ),
    SiteProfile(
      domain: 'wuxiaworld.com',
      contentSelectors: ['.chapter-content', '#chapter-content'],
      nextChapterSelectors: ['.next-chapter', 'a.next'],
      titleSelectors: ['h4', '.chapter-title'],
    ),
    SiteProfile(
      domain: 'webnovel.com',
      contentSelectors: ['.cha-words', '.chapter-content', '.read-content'],
      nextChapterSelectors: ['.j_next_chapter', '.next-chapter'],
      titleSelectors: ['.cha-tit', '.chapter-title'],
    ),
    SiteProfile(
      domain: 'boxnovel.com',
      contentSelectors: ['.text-left', '.reading-content'],
      nextChapterSelectors: ['.next_page', '.next-chap'],
      titleSelectors: ['.breadcrumb li:last-child', 'h1'],
    ),
    SiteProfile(
      domain: 'lightnovelworld.com',
      contentSelectors: ['#chapter-container', '.chapter-content'],
      nextChapterSelectors: ['a.next-chap', '.next-chapter'],
      titleSelectors: ['.chapter-title', 'h2'],
    ),
    SiteProfile(
      domain: 'lightnovelworld.co',
      contentSelectors: ['#chapter-container', '.chapter-content'],
      nextChapterSelectors: ['a.next-chap', '.next-chapter'],
      titleSelectors: ['.chapter-title', 'h2'],
    ),
    SiteProfile(
      domain: 'mtlnovel.com',
      contentSelectors: ['.reading-content', '.par'],
      nextChapterSelectors: ['.next-chap', 'a.next'],
      titleSelectors: ['.current-crumb', 'h1'],
    ),

    // ─── 69shu family (GBK encoded) ───
    SiteProfile(
      domain: '69shu.com',
      contentSelectors: ['.txtnav', '#txtContent', '.novelcontent'],
      nextChapterSelectors: ['#next_url', '#next', '.p1 a:last-child'],
      titleSelectors: ['h1', '.bread-crumb'],
      stripSelectors: [
        '.txtinfo', '#txtright', '.contentadv',
        '.bottom-ad', '.bottom-ad2', '.page1', 'script', 'style',
      ],
      charset: 'gbk',
    ),
    // 69shuba.com  —  /txt/<bookId>/<chapterId>
    SiteProfile(
      domain: '69shuba.com',
      contentSelectors: ['.txtnav', '#txtContent', '.novelcontent'],
      nextChapterSelectors: ['#next_url', '#next', '.p1 a:last-child'],
      titleSelectors: ['h1', '.bread-crumb', '.title'],
      stripSelectors: [
        '.txtinfo', '#txtright', '.contentadv',
        '.bottom-ad', '.bottom-ad2', '.page1', 'script', 'style',
      ],
      charset: 'gbk',
    ),
    // 69shuba.tw  —  /read/<bookId>/<chapterId>  (same HTML structure, GBK)
    SiteProfile(
      domain: '69shuba.tw',
      contentSelectors: ['.txtnav', '#txtContent', '.novelcontent'],
      nextChapterSelectors: ['#next_url', '#next', '.p1 a:last-child'],
      titleSelectors: ['h1', '.bread-crumb', '.title'],
      stripSelectors: [
        '.txtinfo', '#txtright', '.contentadv',
        '.bottom-ad', '.bottom-ad2', '.page1', 'script', 'style',
      ],
      charset: 'gbk',
    ),
    // 69shubha.com (legacy alias)
    SiteProfile(
      domain: '69shubha.com',
      contentSelectors: ['.txtnav', '#txtContent', '.novelcontent'],
      nextChapterSelectors: ['#next_url', '#next', '.p1 a:last-child'],
      titleSelectors: ['h1', '.bread-crumb'],
      stripSelectors: [
        '.txtinfo', '#txtright', '.contentadv',
        '.bottom-ad', '.page1', 'script', 'style',
      ],
      charset: 'gbk',
    ),

    SiteProfile(
      domain: 'novelnest.com',
      contentSelectors: ['.reading-content', '#chapter-content', '.text-left'],
      nextChapterSelectors: ['.next_page', '.next-chap', 'a.next'],
      titleSelectors: ['.chapter-title', 'h1', 'h2'],
    ),

    // ─── 8book / thepaperbooks family (UTF-8) ───
    SiteProfile(
      domain: '8book.com',
      contentSelectors: ['.txtnav', '#content', '#TextContent', '.readcontent', '.chapter_content', '.post-content', '.entry-content', '#nr_content', '.book_content', '.article-content', '.novel-content'],
      nextChapterSelectors: ['#next_url', '#next', 'a.next'],
      titleSelectors: ['h1', '.title'],
      stripSelectors: ['.txtinfo', '.page1', 'script', 'style'],
    ),
    SiteProfile(
      domain: 'thepaperbooks.com',
      contentSelectors: ['.txtnav', '#content', '#TextContent', '.readcontent', '.chapter_content', '.post-content', '.entry-content', '#nr_content', '.book_content', '.article-content', '.novel-content'],
      nextChapterSelectors: ['#next_url', '#next', 'a.next'],
      titleSelectors: ['h1', '.title'],
      stripSelectors: ['.txtinfo', '.page1', 'script', 'style'],
    ),
    // sport.thepaperbooks.com is a subdomain of thepaperbooks.com — explicit entry
    SiteProfile(
      domain: 'sport.thepaperbooks.com',
      contentSelectors: ['.txtnav', '#content', '#TextContent', '.readcontent', '.chapter_content', '.post-content', '.entry-content', '#nr_content', '.book_content', '.article-content', '.novel-content'],
      nextChapterSelectors: ['#next_url', '#next', 'a.next'],
      titleSelectors: ['h1', '.title'],
      stripSelectors: ['.txtinfo', '.page1', 'script', 'style'],
    ),

    SiteProfile(
      domain: 'uukanshu.com',
      contentSelectors: ['#contentbox', '.readcontent'],
      nextChapterSelectors: ['#next', 'a.next'],
      titleSelectors: ['h1', '#timark'],
      charset: 'gbk',
    ),
    SiteProfile(
      domain: 'syosetu.com',
      contentSelectors: ['#novel_honbun', '.novel_view'],
      nextChapterSelectors: ['.novel_bn a:last-child'],
      titleSelectors: ['.novel_subtitle', 'h1'],
    ),
    SiteProfile(
      domain: 'kakuyomu.jp',
      contentSelectors: ['.widget-episodeBody', '.js-episode-body'],
      nextChapterSelectors: ['#contentMain-nextEpisode a', '.next-episode'],
      titleSelectors: ['.widget-episodeTitle', 'h1'],
    ),
    SiteProfile(
      domain: 'novelpia.com',
      contentSelectors: ['#episode_cont', '.novel-content'],
      nextChapterSelectors: ['.next-episode'],
      titleSelectors: ['.episode-title', 'h2'],
    ),
    SiteProfile(
      domain: 'ridibooks.com',
      contentSelectors: ['.chapter_view', '.ridi_content'],
      nextChapterSelectors: ['.next-chapter', 'a.next'],
      titleSelectors: ['.chapter_title', 'h2'],
    ),
  ];

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Scrape a chapter from [url] and return the structured result.
  static Future<ScrapedChapter> scrapeChapter(String url) async {
    final uri = Uri.parse(url);
    final profile = _findProfile(uri.host);

    // Fetch raw bytes so we can handle any encoding
    final rawBytes = await _fetchBytes(url);

    // Determine the encoding: profile hint → meta-tag detection → utf-8
    final charset = profile?.charset ?? _sniffCharset(rawBytes);
    final html = _decode(rawBytes, charset);

    final document = html_parser.parse(html);

    final title = _extractTitle(document, profile) ?? 'Untitled Chapter';

    // 8book / sport.thepaperbooks.com specific interceptor for dynamic text
    if (uri.host.contains('8book.com') || uri.host.contains('sport.thepaperbooks.com')) {
      final textUrl = _extract8bookTextUrl(html, uri.toString());
      if (textUrl != null) {
        final textBytes = await _fetchBytes(textUrl);
        final textHtml = _decode(textBytes, 'utf-8');
        String content = textHtml
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
            .replaceAll(RegExp(r'</?p[^>]*>', caseSensitive: false), '\n')
            .replaceAll(RegExp(r'</?div[^>]*>', caseSensitive: false), '\n')
            .replaceAll(RegExp(r'<[^>]+>'), '');
            
        content = content.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).join('\n\n');
        content = _sanitize(content);
        
        return ScrapedChapter(
          title: title,
          content: content,
          nextChapterUrl: _detectNextUrl(document, uri, profile),
          detectedLanguage: detectLanguage(content),
        );
      }
    }

    String content = profile != null
        ? _extractWithProfile(document, profile)
        : _extractGeneric(document);

    content = _sanitize(content);

    if (content.isEmpty) {
      throw Exception(
        'Could not extract chapter content from ${uri.host}. '
        'The page may require JavaScript or a login.',
      );
    }

    final nextUrl = _detectNextUrl(document, uri, profile);
    final language = detectLanguage(content);

    return ScrapedChapter(
      title: title,
      content: content,
      nextChapterUrl: nextUrl,
      detectedLanguage: language,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HTTP
  // ──────────────────────────────────────────────────────────────────────────

  static Future<List<int>> _fetchBytes(String url) async {
    // Sanitize the URL to remove accidental copy-paste spaces
    String fetchUrl = url.trim().replaceAll(RegExp(r'\s+'), '');
    if (kIsWeb) {
      fetchUrl = '${AppDefaults.corsProxy}${Uri.encodeComponent(fetchUrl)}';
    }

    final parsedUri = Uri.parse(fetchUrl);
    final client = http.Client();
    try {
      final response = await client.get(
        parsedUri,
        headers: {
          'User-Agent': AppDefaults.userAgent,
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          'Referer': parsedUri.origin,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode} from ${Uri.parse(url).host}');
      }

      return response.bodyBytes;
    } finally {
      client.close();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Encoding
  // ──────────────────────────────────────────────────────────────────────────

  /// Peek at the first 2 KB (as latin-1) to find a charset meta declaration.
  static String _sniffCharset(List<int> bytes) {
    final preview = latin1.decode(
      bytes.sublist(0, bytes.length < 2048 ? bytes.length : 2048),
      allowInvalid: true,
    );
    // Match: charset=gbk  charset="utf-8"  charset='gb2312'  (with or without quotes)
    // Avoid putting quote chars in the pattern to prevent MSBuild XML parse issues.
    final m = RegExp(r'charset\s*=\s*[\w-]+', caseSensitive: false)
        .firstMatch(preview);
    if (m != null) {
      // Extract just the value after the '='
      final raw = m.group(0)!;
      final eq = raw.indexOf('=');
      final cs = raw.substring(eq + 1).trim().toLowerCase().replaceAll('-', '');
      if (cs.contains('gbk') || cs.contains('gb2312') || cs.contains('gb18030')) {
        return 'gbk';
      }
    }
    return 'utf-8';
  }

  /// Decode [bytes] using [charset] ('gbk' or 'utf-8').
  static String _decode(List<int> bytes, String charset) {
    if (charset == 'gbk') {
      try {
        return gbk.decode(bytes);
      } catch (_) {
        // Fallback: try utf-8, then latin-1
        try {
          return utf8.decode(bytes, allowMalformed: true);
        } catch (_) {
          return latin1.decode(bytes, allowInvalid: true);
        }
      }
    }
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Profile lookup
  // ──────────────────────────────────────────────────────────────────────────

  static SiteProfile? _findProfile(String host) {
    // Try exact match first (handles subdomains like sport.thepaperbooks.com)
    for (final p in _siteProfiles) {
      if (host == p.domain || host == 'www.${p.domain}') return p;
    }
    // Then suffix match
    final stripped = host.replaceFirst(RegExp(r'^www\.'), '');
    for (final p in _siteProfiles) {
      if (stripped == p.domain || stripped.endsWith('.${p.domain}')) return p;
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Content extraction
  // ──────────────────────────────────────────────────────────────────────────

  static String? _extractTitle(Document doc, SiteProfile? profile) {
    if (profile != null) {
      for (final sel in profile.titleSelectors) {
        try {
          final el = doc.querySelector(sel);
          if (el != null && el.text.trim().isNotEmpty) return el.text.trim();
        } catch (_) {}
      }
    }
    for (final tag in ['h1', 'h2', 'title']) {
      final el = doc.querySelector(tag);
      if (el != null && el.text.trim().isNotEmpty) return el.text.trim();
    }
    return null;
  }

  static String _extractWithProfile(Document doc, SiteProfile profile) {
    for (final sel in profile.contentSelectors) {
      try {
        final el = doc.querySelector(sel);
        if (el != null) {
          _strip(el, profile.stripSelectors);
          _stripNoise(el);
          return _textFrom(el);
        }
      } catch (_) {}
    }
    return _extractGeneric(doc);
  }

  static String _extractGeneric(Document doc) {
    const common = [
      'article',
      '.chapter-content',
      '#chapter-content',
      '.read-content',
      '.reading-content',
      '.novel-content',
      '.post-content',
      '.entry-content',
      '#nr_content',
      '.book_content',
      '.article-content',
      '#content',
      '.content',
    ];
    for (final sel in common) {
      try {
        final el = doc.querySelector(sel);
        if (el != null && el.text.trim().length > 200) {
          _stripNoise(el);
          return _textFrom(el);
        }
      } catch (_) {}
    }

    // Heuristic: longest <div>
    Element? best;
    int bestLen = 0;
    for (final div in doc.querySelectorAll('div')) {
      final len = div.text.trim().length;
      if (len > bestLen) {
        bestLen = len;
        best = div;
      }
    }
    if (best != null && bestLen > 200) {
      _stripNoise(best);
      return _textFrom(best);
    }

    // Last resort: all <p> tags
    return doc
        .querySelectorAll('p')
        .map((p) => p.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n\n');
  }

  static void _strip(Element el, List<String> selectors) {
    for (final sel in selectors) {
      try {
        el.querySelectorAll(sel).forEach((e) => e.remove());
      } catch (_) {}
    }
  }

  static void _stripNoise(Element el) {
    _strip(el, const [
      'script', 'style', 'nav', 'footer', 'header', 'iframe', 'noscript',
      '.ads', '.ad', '.advertisement', '.social-share', '.comments', '.sidebar',
    ]);
  }

  /// Convert an element to readable text, honouring <br> and <p> breaks.
  static String _textFrom(Element el) {
    // Replace block-level elements with newlines before stripping tags
    final raw = el.innerHtml
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?p[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?div[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ''); // strip remaining tags

    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n\n');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Next chapter detection
  // ──────────────────────────────────────────────────────────────────────────

  static String? _detectNextUrl(
      Document doc, Uri currentUri, SiteProfile? profile) {
    // 1. Profile selectors
    if (profile != null) {
      for (final sel in profile.nextChapterSelectors) {
        try {
          final el = doc.querySelector(sel);
          if (el != null) {
            final href = _safeHref(el);
            if (href != null) return _resolve(href, currentUri);
          }
        } catch (_) {}
      }
    }

    // 2. Anchor text patterns
    const patterns = [
      '下一章', '下一页', '次の章', '次へ', '다음', '다음 챕터',
      'next chapter', 'next',
    ];
    for (final a in doc.querySelectorAll('a')) {
      final txt = a.text.trim().toLowerCase();
      for (final p in patterns) {
        if (txt == p.toLowerCase() || txt.contains(p.toLowerCase())) {
          final href = _safeHref(a);
          if (href != null) return _resolve(href, currentUri);
        }
      }
    }

    // 3. rel="next"
    for (final sel in ['a[rel="next"]', 'link[rel="next"]']) {
      final el = doc.querySelector(sel);
      if (el != null) {
        final href = _safeHref(el);
        if (href != null) return _resolve(href, currentUri);
      }
    }

    // 4. URL increment heuristic
    return _incrementUrl(currentUri);
  }

  static String? _safeHref(Element el) {
    final href = el.attributes['href'];
    if (href == null || href.isEmpty || href == '#') return null;
    if (href.startsWith('javascript:')) return null;
    return href;
  }

  static String _resolve(String nextUrl, Uri baseUri) {
    // Basic fallback: just return the original if it's already absolute
    if (nextUrl.startsWith('http')) return nextUrl;

    // Use Uri class to resolve relative paths against base url
    try {
      final nextUri = baseUri.resolve(nextUrl);
      return nextUri.toString();
    } catch (_) {
      return nextUrl;
    }
  }

  // 8book specific URL extraction
  static String? _extract8bookTextUrl(String html, String pageUrl) {
    try {
      final itemIdMatch = RegExp(r'<meta name="itemid" content="(\d+)"').firstMatch(html);
      if (itemIdMatch == null) return null;
      final itemId = int.parse(itemIdMatch.group(1)!);

      final uri = Uri.parse(pageUrl);
      // The chapter ID is usually the last segment or query param
      String chapterId = '';
      if (uri.query.isNotEmpty && RegExp(r'\d+').hasMatch(uri.query)) {
        chapterId = RegExp(r'\d+').firstMatch(uri.query)!.group(0)!;
      } else {
        chapterId = uri.pathSegments.last.replaceAll(RegExp(r'[^0-9]'), '');
      }
      if (chapterId.isEmpty) return null;

      final q77Match = RegExp(r'var [a-zA-Z0-9_]+="(\d+(?:,\d+)*,(\d{100,}))"\.split\(').firstMatch(html);
      if (q77Match == null) return null;
      final lastString = q77Match.group(2)!;

      final substrMatch = RegExp(r'\.substr\([a-zA-Z0-9_]+ \* ([a-zA-Z0-9_]+) % ([a-zA-Z0-9_]+),\s*([a-zA-Z0-9_]+)\)').firstMatch(html);
      if (substrMatch == null) return null;
      final multVar = substrMatch.group(1);
      final modVar = substrMatch.group(2);
      final lenVar = substrMatch.group(3);

      final multValStr = RegExp('var $multVar=(\\d+);').firstMatch(html)?.group(1);
      final modValStr = RegExp('var $modVar=(\\d+);').firstMatch(html)?.group(1);
      final lenValStr = RegExp('var $lenVar=(\\d+);').firstMatch(html)?.group(1);

      if (multValStr == null || modValStr == null || lenValStr == null) return null;

      final mult = int.parse(multValStr);
      final mod = int.parse(modValStr);
      final len = int.parse(lenValStr);

      final cId = int.parse(chapterId);
      final idx = (cId * mult) % mod;
      final hash = lastString.substring(idx, idx + len);

      final idPrefix = itemId ~/ 100000;
      return 'https://${uri.host}/txt/$idPrefix/$itemId/$chapterId$hash.html';
    } catch (e) {
      print('Failed to extract 8book text url: $e');
      return null;
    }
  }

  static String? _incrementUrl(Uri uri) {
    final path = uri.toString();

    // chapter-45 / chapter_45
    final re1 = RegExp(r'(chapter[_-])(\d+)');
    final m1 = re1.firstMatch(path);
    if (m1 != null) {
      final n = int.parse(m1.group(2)!);
      return path.replaceFirst(re1, '${m1.group(1)}${n + 1}');
    }

    // -c45
    final re2 = RegExp(r'(-c)(\d+)');
    final m2 = re2.firstMatch(path);
    if (m2 != null) {
      final n = int.parse(m2.group(2)!);
      return path.replaceFirst(re2, '${m2.group(1)}${n + 1}');
    }

    // ?chapter=45
    if (uri.queryParameters.containsKey('chapter')) {
      final n = int.tryParse(uri.queryParameters['chapter']!);
      if (n != null) {
        final q = Map<String, String>.from(uri.queryParameters)
          ..['chapter'] = '${n + 1}';
        return uri.replace(queryParameters: q).toString();
      }
    }

    // trailing numeric segment: /4031644 → /4031645
    final re3 = RegExp(r'([/_])(\d+)(?:[/]?)$');
    final m3 = re3.firstMatch(path);
    if (m3 != null) {
      final n = int.parse(m3.group(2)!);
      return path.replaceFirst(re3, '${m3.group(1)}${n + 1}');
    }

    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sanitisation
  // ──────────────────────────────────────────────────────────────────────────

  static String _sanitize(String content) {
    var s = content;

    for (final pat in AdPatterns.adRegexes) {
      s = s.replaceAll(pat, '');
    }

    // Remove lines that are bare URLs
    s = s
        .split('\n')
        .where((l) => !RegExp(r'^\s*https?://\S+\s*$').hasMatch(l))
        .join('\n');

    s = s
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return s;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Language detection
  // ──────────────────────────────────────────────────────────────────────────

  static String detectLanguage(String text) {
    if (text.isEmpty) return 'unknown';

    int cjk = 0, hangul = 0, kana = 0, total = 0;
    for (final r in text.runes) {
      if (r == 0x20 || r == 0x0A || r == 0x0D) continue;
      total++;
      if (r >= 0x4E00 && r <= 0x9FFF) cjk++;
      if (r >= 0xAC00 && r <= 0xD7AF) hangul++;
      if ((r >= 0x3040 && r <= 0x309F) || (r >= 0x30A0 && r <= 0x30FF)) kana++;
    }
    if (total == 0) return 'unknown';

    if (hangul / total > 0.10) return 'Korean';
    if (kana / total > 0.05) return 'Japanese';
    if (cjk / total > 0.20) return 'Chinese';
    return 'unknown';
  }
}
