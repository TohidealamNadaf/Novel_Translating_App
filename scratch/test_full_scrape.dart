import 'dart:io';
import '../lib/services/chapter_scraper_service.dart';

void main() async {
  final url = 'https://sport.thepaperbooks.com/read/297656/?13877674';
  try {
    final scraped = await ChapterScraperService.scrapeChapter(url);
    File('debug_scraped.txt').writeAsStringSync(scraped.content);
    print('Scraped successfully! Saved to debug_scraped.txt. Length: ${scraped.content.length}');
  } catch (e) {
    print('Error: $e');
  }
}
