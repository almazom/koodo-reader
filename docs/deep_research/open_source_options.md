# Open Source EPUB Reader Options Analysis

## Cross-Platform Options

### Koodo Reader
- **Technology**: React-based
- **Platforms**: Web, desktop (Windows, macOS, Linux), Android, iOS
- **GitHub Stars**: 21.5k+
- **License**: AGPL-3.0
- **Features**:
  - Multiple formats support (EPUB, PDF, MOBI, etc.)
  - Customizable layouts
  - Text-to-speech functionality
  - Built-in AI features (AI Translation, AI Dictionary, AI Summary in Pro version)
  - Sync functionality
- **Development Status**: Active
- **Strengths**: Modern architecture, existing AI features, cross-platform, active development
- **URL**: [https://github.com/koodo-reader](https://github.com/koodo-reader)

### Readest
- **Technology**: Next.js, Tauri
- **Platforms**: macOS, Windows, Linux, Android, iOS, Web
- **Features**:
  - Multi-format support
  - Scroll/page view modes
  - Sync across platforms
  - Planned AI summarization
- **Development Status**: Active
- **License**: AGPL-3.0
- **Strengths**: Modern architecture, developer documentation

### KOReader
- **Technology**: Lua-based
- **Platforms**: Multiple, including E-ink devices
- **Features**: 
  - Optimized for e-reader devices
  - PDF reflow
  - Dictionary support
- **Strengths**: Optimized for e-ink readers
- **Limitations**: Less ideal for modern touchscreen mobile apps

## Android-Specific Options

### Librera Reader
- **Technology**: Java/Kotlin
- **Downloads**: 10M+
- **Features**:
  - Supports multiple formats (EPUB, PDF, MOBI)
  - TOC, navigation, bookmarks
  - Cloud sync
- **Development Status**: Frozen (as of research date)
- **License**: GPL
- **Strengths**: Widely used, feature-rich
- **Limitations**: Development is no longer active
- **URL**: [https://github.com/foobnix/LibreraReader](https://github.com/foobnix/LibreraReader)

### Book Reader
- **Note**: Fork of early FBReader
- **Formats**: EPUB, mobi, PDF, DjVu
- **Availability**: F-Droid
- **Strengths**: Lightweight, open-source
- **Limitations**: Less modern UI

### Book's Story
- **Technology**: Kotlin
- **Features**: Material You design, multiple formats, customizable library
- **License**: GPL-3.0
- **Strengths**: Modern Android-native design

### Openlib
- **Technology**: Flutter (Dart)
- **Features**: Downloads and reads from shadow libraries, supports EPUB and PDF
- **License**: GPL-3.0
- **Strengths**: Flutter-based (potential for cross-platform)

## iOS-Specific Options

### FolioReaderKit
- **Type**: Framework (not full app)
- **Language**: Swift
- **Features**: 
  - EPUB parsing, rendering, navigation
  - Text selection
  - Basic TTS
- **License**: BSD-3-Clause
- **Strengths**: Solid foundation for iOS development
- **Limitations**: Framework, not a complete app (requires building UI)

### kybook
- **Language**: Objective-C
- **Formats**: EPUB, FB2, PDF, DJVU, TXT, RTF
- **Features**: OPDS support, cloud integration
- **Strengths**: Comprehensive format support
- **Limitations**: Older codebase

### iRead
- **Language**: Swift
- **Type**: Full EPUB reader app
- **Strengths**: Native iOS app
- **Limitations**: Potentially less feature-rich than alternatives

### EpubReader-iOS
- **Language**: Swift
- **Features**: Custom fonts, highlighting, TTS, multiple instances
- **License**: Apache-2.0
- **Strengths**: Modern Swift implementation

## SDK Options

### Readium SDK
- **Language**: C++
- **License**: BSD (allows commercial use)
- **Strengths**: 
  - Cross-platform
  - Mature project
  - Commercial-friendly license
- **Use case**: Good option if needing lower-level control but not starting from scratch

### epuBear
- **Type**: Cross-platform SDK
- **Platforms**: Android (Java), iOS (Swift), Xamarin (C#)
- **Features**: EPUB parsing and rendering
- **Limitations**: May have commercial licensing requirements

### SkyePUB SDK
- **Platforms**: iOS and Android
- **Adoption**: Used by 1000+ companies
- **Features**: Comprehensive EPUB handling
- **Limitations**: Likely commercial/paid

### AnFengDe EPUB SDK
- **Platform**: Android
- **License**: Free SDK
- **Strengths**: Free for Android development
- **Limitations**: Android-only

## Recommendation

Based on the comprehensive analysis of available options, **Koodo Reader** emerges as the most suitable foundation for the project, with these key advantages:

1. **Cross-platform support** covering all target platforms
2. **Existing AI features** that demonstrate feasibility of LLM integration
3. **Active development** with modern architecture
4. **Strong community** with 21.5k+ GitHub stars

For platform-specific development:
- **Android**: Librera Reader (despite frozen development)
- **iOS**: FolioReaderKit framework

However, the cross-platform approach with Koodo Reader is recommended to maximize development efficiency and maintain consistent experience across platforms. 