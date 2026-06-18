# NovelShift 📖✨

**AI-Powered Web Novel Translator** — Translate Chinese, Korean, and Japanese web novels into English using your own LLM API keys.

## Features

- 🤖 **Multi-Model AI Support** — OpenAI (GPT-4o), Google Gemini, Mistral, DeepSeek
- 📚 **Smart Chapter Scraping** — Auto-detects content from 16+ popular novel sites
- 🔄 **Next-Chapter Detection** — Intelligent URL detection and heuristic chapter increment
- 📝 **Persistent Glossary** — Auto-extracts and manages character names, terms, and places
- 🎨 **Beautiful Reading UI** — Dark, Sepia, and Light themes with serif/sans-serif font options
- 📱 **Cross-Platform** — Android APK + Flutter Web from a single codebase
- 🔐 **Secure** — API keys stored in flutter_secure_storage; never logged or exposed
- 💾 **Offline Reading** — Translated chapters saved to SQLite for re-reading

## Supported Novel Sites

| Site | Language | Domain |
|------|----------|--------|
| NovelBin | EN/CN | novelbin.me, novelbin.net |
| ReadNovelFull | EN/CN | readnovelfull.com |
| WuxiaWorld | EN/CN | wuxiaworld.com |
| WebNovel | EN/CN | webnovel.com |
| BoxNovel | EN/CN | boxnovel.com |
| LightNovelWorld | EN/CN | lightnovelworld.com |
| MTLNovel | CN | mtlnovel.com |
| 69shu | CN | 69shu.com |
| 69shubha | CN | 69shubha.com |
| NovelNest | EN/CN | novelnest.com |
| 8book | CN | 8book.com | sport.thepaperbooks.com/read |
| UUKanShu | CN | uukanshu.com |
| Syosetu | JP | syosetu.com |
| Kakuyomu | JP | kakuyomu.jp |
| NovelPia | KR | novelpia.com |
| Ridibooks | KR | ridibooks.com |

*Any other site will use the generic fallback scraper.*

## Getting Started

### Prerequisites

- Flutter SDK (3.24+)
- Dart SDK (3.4+)

### Installation

```bash
git clone https://github.com/your-username/novel-shift.git
cd novel-shift
flutter pub get
```

### Run

```bash
# Android
flutter run

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

### Build

```bash
# Android APK
flutter build apk --debug

# Web
flutter build web --release
```

## Configuration

1. Launch the app
2. Go to **Settings** → **API Keys**
3. Enter your API key for at least one provider (OpenAI, Gemini, Mistral, or DeepSeek)
4. Select your preferred default model

## Usage

1. Tap **Add Novel** from the library
2. **By URL** — Paste a chapter URL → Fetch & Preview → Add to Library
3. **By Text** — Paste raw foreign text → Select language → Translate
4. The **Reader** screen shows the translated chapter with inline editing support
5. Tap **Next →** to auto-detect and translate the next chapter
6. Manage the **Glossary** to ensure consistent character/term translations

## CORS Note (Web)

When running as Flutter Web, direct HTTP requests to novel sites will be blocked by CORS. For web deployment, you need a CORS proxy (e.g., `https://corsproxy.io/`) or a small backend proxy. The mobile APK does not have this limitation.

## GitHub Actions

The included `.github/workflows/build.yml` builds both an Android APK and Web bundle on push to `main`. No Android Studio required.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Navigation | go_router |
| Database | sqflite |
| HTTP | http package |
| HTML Parsing | html package |
| Secure Storage | flutter_secure_storage |
| Typography | Google Fonts |

## License

MIT
