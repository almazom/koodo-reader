# Core LLM Features Requirements

## Overview

Based on our interview discussions, Koodo Reader will be enhanced with LLM capabilities to serve as an AI reading companion, particularly for complex philosophical texts. The system will leverage the full power of large language models to process entities such as chapters, selected text passages, and entire books.

## Primary User Need

The core purpose is to create an AI companion that:
- Helps readers understand complex texts
- Explains difficult concepts and terminology
- Answers questions about the content
- Facilitates deeper exploration of complex topics
- Serves as a discussion partner for readers

## Feature Priorities

### 1. Chapter Summarization (Highest Priority)

The initial focus will be on implementing chapter summarization, leveraging the existing book structure with its table of contents, chapters, and subchapters.

#### Key Requirements:
- **On-demand generation**: Users must explicitly request summaries by clicking a button
- **Persistence**: Summaries must be stored in the database for future reference
- **Visual indicators**: Show when summaries exist for chapters
- **Regeneration**: Allow users to regenerate summaries if needed
- **Mobile-first design**: Prioritize Android mobile interface

### 2. Question Answering (Future)

Enabling users to ask questions about text content and receive contextually relevant answers.

### 3. Content Analysis (Future)

Analyzing themes, characters, and complex terminology in the text.

### 4. Discussion Partner (Future)

Allowing readers to discuss and share thoughts about the material with the AI.

## LLM Integration Approach

### API Provider Support

The system will follow a "Bring Your Own Keys" (BYOK) model, where users provide their own API keys in the settings. Initial support for:

1. DeepSeek v3
2. DeepSeek R1
3. Gwen 2.5 max
4. Minimax
5. Gemini Flash 2.0

### Key Technical Considerations:

- User-provided API keys must be securely stored
- Settings interface for managing multiple LLM providers
- Clear indicators of which provider is being used
- Appropriate error handling for API issues

## UI Integration Guidelines

- Leverage existing UI components in Koodo Reader
- Design with mobile-first approach (prioritizing Android)
- Maintain the clean reading experience
- Include visual indicators for available AI content
- Provide intuitive access to AI features 