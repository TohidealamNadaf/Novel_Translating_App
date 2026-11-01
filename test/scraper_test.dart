import 'package:flutter_test/flutter_test.dart';
import 'package:novel_shift/services/chapter_scraper_service.dart';

void main() {
  test('Scrape chapter and detect next URL', () async {
    final url = 'https://sport.thepaperbooks.com/read/297656/?13877674';
    final scraped = await ChapterScraperService.scrapeChapter(url);
    print('TITLE: ${scraped.title}');
    print('CONTENT LENGTH: ${scraped.content.length}');
    print('NEXT CHAPTER URL: ${scraped.nextChapterUrl}');
    print('LANGUAGE: ${scraped.detectedLanguage}');
    
    // Verify next chapter was detected
    expect(scraped.nextChapterUrl, isNotNull, reason: 'Next chapter URL should be detected');
    expect(scraped.nextChapterUrl, contains('13877675'), reason: 'Next chapter ID should be 13877675');
  });
}
