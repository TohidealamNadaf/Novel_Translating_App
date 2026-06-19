import 'package:flutter_test/flutter_test.dart';
import 'package:novel_shift/services/chapter_scraper_service.dart';

void main() {
  test('Scrape chapter', () async {
    final url = 'https://8book.com/read/297656/?13877673';
    final scraped = await ChapterScraperService.scrapeChapter(url);
    print('SCRAPED LENGTH: ${scraped.content.length}');
    print('SCRAPED PREVIEW: ${scraped.content}');
  });
}
