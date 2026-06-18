import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:flutter/foundation.dart';
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

  const SiteProfile({
    required this.domain,
    required this.contentSelectors,
    required this.nextChapterSelectors,
    required this.titleSelectors,
  });
}

class ChapterScraperService {
  // ─── Pre-configured site profiles ───
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
    SiteProfile(
      domain: '69shu.com',
      contentSelectors: ['.txtnav', '#txtContent', '.novelcontent'],
      nextChapterSelectors: ['.p1 a:last-child', 'a:contains(下一章)'],
      titleSelectors: ['h1', '.bread-crumb'],
    ),
    SiteProfile(
      domain: '69shubha.com',
      contentSelectors: ['.txtnav', '#txtContent', '.novelcontent'],
      nextChapterSelectors: ['.p1 a:last-child', 'a:contains(下一章)'],
      titleSelectors: ['h1', '.bread-crumb'],
    ),
    SiteProfile(
      domain: 'novelnest.com',
      contentSelectors: ['.reading-content', '#chapter-content', '.text-left'],
      nextChapterSelectors: ['.next_page', '.next-chap', 'a.next'],
      titleSelectors: ['.chapter-title', 'h1', 'h2'],
    ),
    SiteProfile(
      domain: '8book.com',
      contentSelectors: ['#content', '#TextContent', '.readcontent'],
      nextChapterSelectors: ['#next_url', '#next', 'a:contains(下一章)'],
      titleSelectors: ['h1', '.title'],
    ),
    SiteProfile(
      domain: 'sport.thepaperbooks.com',
      contentSelectors: ['#content', '#TextContent', '.readcontent'],
      nextChapterSelectors: ['#next_url', '#next', 'a:contains(下一章)'],
      titleSelectors: ['h1', '.title'],
    ),
    SiteProfile(
      domain: 'uukanshu.com',
      contentSelectors: ['#contentbox', '.readcontent'],
      nextChapterSelectors: ['#next', 'a:contains(下一章)'],
      titleSelectors: ['h1', '#timark'],
    ),
    SiteProfile(
      domain: 'syosetu.com',
      contentSelectors: ['#novel_honbun', '.novel_view'],
      nextChapterSelectors: ['.novel_bn a:last-child', 'a:contains(次の章)'],
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
      nextChapterSelectors: ['.next-episode', 'a:contains(다음)'],
      titleSelectors: ['.episode-title', 'h2'],
    ),
    SiteProfile(
      domain: 'ridibooks.com',
      contentSelectors: ['.chapter_view', '.ridi_content'],
      nextChapterSelectors: ['.next-chapter', 'a.next'],
      titleSelectors: ['.chapter_title', 'h2'],
    ),
  ];

  /// Scrape a chapter from the given URL
  static Future<ScrapedChapter> scrapeChapter(String url) async {
    final html = await _fetchHtml(url);
    final document = html_parser.parse(html);
    final uri = Uri.parse(url);
    final profile = _findProfile(uri.host);

    // Extract title
    final title = _extractTitle(document, profile) ?? 'Untitled Chapter';

    // Extract content
    String content;
    if (profile != null) {
      content = _extractContentWithProfile(document, profile);
    } else {
      content = _extractContentGeneric(document);
    }

    // Sanitize
    content = _sanitizeContent(content);

    // Detect next chapter URL
    final nextUrl = _detectNextChapterUrl(document, uri, profile, html);

    // Detect language
    final language = detectLanguage(content);

    return ScrapedChapter(
      title: title,
      content: content,
      nextChapterUrl: nextUrl,
      detectedLanguage: language,
    );
  }

  /// Fetch raw HTML from URL
  static Future<String> _fetchHtml(String url) async {
    String fetchUrl = url;

    // On web, use CORS proxy
    if (kIsWeb) {
      fetchUrl = '${AppDefaults.corsProxy}${Uri.encodeComponent(url)}';
    }

    final response = await http.get(
      Uri.parse(fetchUrl),
      headers: {'User-Agent': AppDefaults.userAgent},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch page: HTTP ${response.statusCode}');
    }

    return response.body;
  }

  /// Find matching site profile
  static SiteProfile? _findProfile(String host) {
    final normalizedHost = host.replaceFirst(RegExp(r'^www\.'), '');
    for (final profile in _siteProfiles) {
      if (normalizedHost == profile.domain ||
          normalizedHost.endsWith('.${profile.domain}')) {
        return profile;
      }
    }
    return null;
  }

  /// Extract title using profile selectors or fallback
  static String? _extractTitle(Document document, SiteProfile? profile) {
    if (profile != null) {
      for (final selector in profile.titleSelectors) {
        try {
          final element = document.querySelector(selector);
          if (element != null && element.text.trim().isNotEmpty) {
            return element.text.trim();
          }
        } catch (_) {}
      }
    }

    // Fallback: <h1>, <h2>, or <title>
    for (final tag in ['h1', 'h2', 'title']) {
      final el = document.querySelector(tag);
      if (el != null && el.text.trim().isNotEmpty) {
        return el.text.trim();
      }
    }
    return null;
  }

  /// Extract content using site profile selectors
  static String _extractContentWithProfile(
      Document document, SiteProfile profile) {
    for (final selector in profile.contentSelectors) {
      try {
        final element = document.querySelector(selector);
        if (element != null) {
          _stripUnwantedElements(element);
          return _extractText(element);
        }
      } catch (_) {}
    }
    // Fall back to generic
    return _extractContentGeneric(document);
  }

  /// Generic content extraction fallback
  static String _extractContentGeneric(Document document) {
    // Try common selectors
    final commonSelectors = [
      'article',
      '.chapter-content',
      '#chapter-content',
      '.read-content',
      '.reading-content',
      '.novel-content',
      '#content',
      '.content',
    ];

    for (final selector in commonSelectors) {
      try {
        final element = document.querySelector(selector);
        if (element != null && element.text.trim().length > 200) {
          _stripUnwantedElements(element);
          return _extractText(element);
        }
      } catch (_) {}
    }

    // Heuristic: find the longest <div> by text length
    final divs = document.querySelectorAll('div');
    Element? longestDiv;
    int maxLength = 0;

    for (final div in divs) {
      final textLength = div.text.trim().length;
      if (textLength > maxLength) {
        maxLength = textLength;
        longestDiv = div;
      }
    }

    if (longestDiv != null && maxLength > 200) {
      _stripUnwantedElements(longestDiv);
      return _extractText(longestDiv);
    }

    // Last resort: all <p> tags
    final paragraphs = document.querySelectorAll('p');
    return paragraphs.map((p) => p.text.trim()).where((t) => t.isNotEmpty).join('\n\n');
  }

  /// Strip scripts, styles, navs, ads from an element
  static void _stripUnwantedElements(Element element) {
    final selectorsToRemove = [
      'script',
      'style',
      'nav',
      'footer',
      'header',
      '.ads',
      '.ad',
      '.advertisement',
      '.social-share',
      '.comments',
      '.sidebar',
      'iframe',
      'noscript',
    ];

    for (final selector in selectorsToRemove) {
      try {
        element.querySelectorAll(selector).forEach((e) => e.remove());
      } catch (_) {}
    }
  }

  /// Extract text from element, preserving paragraph breaks
  static String _extractText(Element element) {
    final paragraphs = element.querySelectorAll('p');
    if (paragraphs.isNotEmpty) {
      return paragraphs
          .map((p) => p.text.trim())
          .where((t) => t.isNotEmpty)
          .join('\n\n');
    }

    // If no <p> tags, split by <br> and newlines
    final html = element.innerHtml;
    final text = html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n\n');

    return text;
  }

  /// Detect next chapter URL — uses priority order from spec
  static String? _detectNextChapterUrl(
    Document document,
    Uri currentUri,
    SiteProfile? profile,
    String rawHtml,
  ) {
    // 1. Site profile selectors
    if (profile != null) {
      for (final selector in profile.nextChapterSelectors) {
        try {
          final element = document.querySelector(selector);
          if (element != null) {
            final href = element.attributes['href'];
            if (href != null && href.isNotEmpty) {
              return _resolveUrl(href, currentUri);
            }
          }
        } catch (_) {}
      }
    }

    // 2. Search for <a> with "next chapter" text patterns
    final nextPatterns = [
      'next chapter',
      'next',
      '下一章',
      '다음 챕터',
      '다음',
      '次の章',
      '次へ',
    ];

    final anchors = document.querySelectorAll('a');
    for (final anchor in anchors) {
      final text = anchor.text.trim().toLowerCase();
      for (final pattern in nextPatterns) {
        if (text.contains(pattern)) {
          final href = anchor.attributes['href'];
          if (href != null && href.isNotEmpty && href != '#') {
            return _resolveUrl(href, currentUri);
          }
        }
      }
    }

    // 3. <a rel="next">
    final relNext = document.querySelector('a[rel="next"]');
    if (relNext != null) {
      final href = relNext.attributes['href'];
      if (href != null && href.isNotEmpty) {
        return _resolveUrl(href, currentUri);
      }
    }

    // 4. <link rel="next">
    final linkNext = document.querySelector('link[rel="next"]');
    if (linkNext != null) {
      final href = linkNext.attributes['href'];
      if (href != null && href.isNotEmpty) {
        return _resolveUrl(href, currentUri);
      }
    }

    // 5. Heuristic URL increment
    return _tryIncrementUrl(currentUri);
  }

  /// Resolve relative URL against base
  static String _resolveUrl(String href, Uri baseUri) {
    if (href.startsWith('http://') || href.startsWith('https://')) {
      return href;
    }
    return baseUri.resolve(href).toString();
  }

  /// Try incrementing chapter number in URL
  static String? _tryIncrementUrl(Uri uri) {
    final path = uri.toString();

    // Pattern: /chapter-45 → /chapter-46
    final chapterDash = RegExp(r'(chapter[_-])(\d+)');
    final dashMatch = chapterDash.firstMatch(path);
    if (dashMatch != null) {
      final num = int.parse(dashMatch.group(2)!);
      return path.replaceFirst(chapterDash, '${dashMatch.group(1)}${num + 1}');
    }

    // Pattern: -c45 → -c46
    final cPattern = RegExp(r'(-c)(\d+)');
    final cMatch = cPattern.firstMatch(path);
    if (cMatch != null) {
      final num = int.parse(cMatch.group(2)!);
      return path.replaceFirst(cPattern, '${cMatch.group(1)}${num + 1}');
    }

    // Pattern: ?chapter=45 → ?chapter=46
    final queryParam = uri.queryParameters['chapter'];
    if (queryParam != null) {
      final num = int.tryParse(queryParam);
      if (num != null) {
        final newQuery = Map<String, String>.from(uri.queryParameters);
        newQuery['chapter'] = '${num + 1}';
        return uri.replace(queryParameters: newQuery).toString();
      }
    }

    // Pattern: trailing number /45 → /46 or _45 → _46
    final trailingNum = RegExp(r'([/_])(\d+)(?:[/]?)$');
    final trailingMatch = trailingNum.firstMatch(path);
    if (trailingMatch != null) {
      final num = int.parse(trailingMatch.group(2)!);
      return path.replaceFirst(
          trailingNum, '${trailingMatch.group(1)}${num + 1}');
    }

    return null;
  }

  /// Sanitize content: remove ads, normalize whitespace
  static String _sanitizeContent(String content) {
    var sanitized = content;

    // Remove ad patterns
    for (final pattern in AdPatterns.adRegexes) {
      sanitized = sanitized.replaceAll(pattern, '');
    }

    // Remove lines that are just URLs
    sanitized = sanitized
        .split('\n')
        .where((line) =>
            !RegExp(r'^\s*https?://').hasMatch(line) || line.trim().length > 100)
        .join('\n');

    // Normalize whitespace but preserve paragraph breaks
    sanitized = sanitized
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return sanitized;
  }

  /// Detect source language from content
  static String detectLanguage(String text) {
    if (text.isEmpty) return 'unknown';

    int cjkCount = 0;
    int hangulCount = 0;
    int jpKanaCount = 0;
    int totalChars = 0;

    for (final rune in text.runes) {
      if (rune == 0x20 || rune == 0x0A || rune == 0x0D) continue;
      totalChars++;

      // CJK Unified Ideographs
      if (rune >= 0x4E00 && rune <= 0x9FFF) cjkCount++;
      // Hangul Syllables
      if (rune >= 0xAC00 && rune <= 0xD7AF) hangulCount++;
      // Hiragana + Katakana
      if ((rune >= 0x3040 && rune <= 0x309F) ||
          (rune >= 0x30A0 && rune <= 0x30FF)) {
        jpKanaCount++;
      }
    }

    if (totalChars == 0) return 'unknown';

    final hangulRatio = hangulCount / totalChars;
    final jpKanaRatio = jpKanaCount / totalChars;
    final cjkRatio = cjkCount / totalChars;

    // Korean check first (Hangul is unambiguous)
    if (hangulRatio > 0.10) return 'Korean';

    // Japanese check (Kana is unambiguous for Japanese)
    if (jpKanaRatio > 0.05) return 'Japanese';

    // Chinese (CJK without Hangul or Kana)
    if (cjkRatio > 0.20) return 'Chinese';

    return 'unknown';
  }
}
