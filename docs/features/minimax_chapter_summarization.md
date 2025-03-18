# Minimax LLM Chapter Summarization Feature

## Overview
This feature will integrate Minimax LLM capabilities into Koodo Reader to provide intelligent chapter summarization functionality.

## Goals
- Implement chapter content extraction using existing Koodo Reader ToC structure
- Integrate Minimax LLM API for text summarization (with DeepSeek-R1 as alternate model)
- Create an intuitive UI using the existing floating AI button
- Ensure efficient caching of summaries in SQLite
- Provide offline access to previously generated summaries
- Support user-editable prompts in Russian language

## Technical Requirements
- Minimax LLM API integration with robust error handling
- SQLite database for caching summaries
- Chapter content extraction using existing rendition system
- UI integration with the existing AI floating button

## Implementation Plan

### Phase 1: Architecture & Core Services
- [ ] Design and implement flexible LLM service layer (supporting Minimax now, others later)
- [ ] Create SQLite database schema and service for summary storage
- [ ] Implement chapter content extraction service
- [ ] Create prompt management system with default Russian prompts

### Phase 2: UI Integration
- [ ] Modify AI floating button to show options menu
- [ ] Add chapter summarization option to the menu
- [ ] Create summary display component
- [ ] Implement loading/progress indicators

### Phase 3: LLM Integration
- [ ] Implement Minimax API client with proper error handling
- [ ] Set up token usage tracking
- [ ] Implement robust retry and fallback mechanisms
- [ ] Create proper error messaging for users

### Phase 4: Settings & Configuration
- [ ] Design prompt editing interface in settings
- [ ] Implement "bring your own API key" functionality
- [ ] Create model selection and configuration options
- [ ] Add summary regeneration controls

## Architecture

### Core Components

#### 1. LLM Service Layer
```typescript
// Flexible architecture supporting multiple LLM providers
interface LLMProvider {
  generateSummary(text: string, options: LLMOptions): Promise<SummaryResult>;
  checkAPIKey(): Promise<boolean>;
  getModelInfo(): LLMModelInfo;
}

// Concrete implementation for Minimax
class MinimaxProvider implements LLMProvider {
  // Supports both MiniMax-Text-01 and DeepSeek-R1 models
}

// Service manager handling providers, retries, fallbacks
class LLMServiceManager {
  private providers: Map<string, LLMProvider>;
  private fallbackChain: string[];
  private retryPolicy: RetryPolicy;
  
  // Methods to handle API communication with proper error handling
}
```

#### 2. Chapter Extraction Service
```typescript
class ChapterExtractor {
  // Leverages existing Koodo Reader chapter structure
  extractCurrentChapter(htmlBook: HtmlBook): Promise<ChapterContent>;
  extractChapterByIndex(htmlBook: HtmlBook, index: number): Promise<ChapterContent>;
}
```

#### 3. SQLite Database Service
```sql
CREATE TABLE chapter_summaries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    book_id TEXT NOT NULL,               -- Unique identifier for the book
    chapter_id TEXT NOT NULL,            -- Unique identifier for the chapter
    chapter_title TEXT NOT NULL,         -- Human-readable chapter title
    model TEXT NOT NULL,                 -- The LLM model used (e.g., "MiniMax-Text-01")
    prompt_id TEXT NOT NULL,             -- Reference to which prompt template was used
    prompt_text TEXT NOT NULL,           -- The actual prompt text used
    summary TEXT NOT NULL,               -- The actual summary content
    created_at INTEGER NOT NULL,         -- Timestamp when summary was generated
    tokens_used INTEGER NOT NULL,        -- Track token usage for monitoring
    tokens_input INTEGER NOT NULL,       -- Input tokens count
    tokens_output INTEGER NOT NULL,      -- Output tokens count
    language TEXT NOT NULL,              -- Language of the summary
    UNIQUE(book_id, chapter_id, model, prompt_id)
);

CREATE INDEX idx_chapter_summaries_lookup ON chapter_summaries(book_id, chapter_id);
```

#### 4. Prompt Management System
```typescript
interface PromptTemplate {
  id: string;
  name: string;
  system_message: string;
  user_template: string;
  parameters: {
    temperature: number;
    max_tokens: number;
    // other model parameters
  };
}

class PromptManager {
  loadDefaultPrompts(): Record<string, PromptTemplate>;
  loadUserPrompts(): Record<string, PromptTemplate>;
  saveUserPrompt(id: string, prompt: PromptTemplate): void;
  getPrompt(id: string): PromptTemplate;
  // Additional prompt management methods
}
```

### Data Flow

1. **User Interaction Flow**
   ```
   User clicks AI floating button → Options menu appears → User selects "Summarize Chapter"
   → System checks if summary exists in SQLite → If exists, display immediately
   → If not, show loading indicator and begin summarization process
   ```

2. **Summarization Process Flow**
   ```
   ChapterExtractor extracts text → LLMServiceManager prepares request
   → Appropriate prompt is selected → Request sent to Minimax API
   → Response processed → Summary stored in SQLite → Summary displayed to user
   ```

3. **Error Handling Flow**
   ```
   API error occurs → Retry with exponential backoff → If continues to fail, try fallback model
   → If all attempts fail, show user-friendly error message with troubleshooting steps
   ```

## Integrations with Existing Koodo Reader Components

### Using Existing ToC Structure
We'll leverage the existing chapter structure in Koodo Reader:
```typescript
// From codebase investigation:
htmlBook.chapters          // Contains chapter structure
htmlBook.flattenChapters   // Linear view of chapters
rendition.getChapter()     // Gets chapter information
rendition.getChapterDoc()  // Gets chapter document
```

### UI Integration with AI Button
We'll modify the existing AI floating button to show a menu of options including chapter summarization.

## API Design

```typescript
// Core interfaces
interface ChapterSummary {
  id: number;
  bookId: string;
  chapterId: string;
  chapterTitle: string;
  model: string;
  promptId: string;
  promptText: string;
  summary: string;
  createdAt: number;
  tokensUsed: number;
  tokensInput: number;
  tokensOutput: number;
  language: string;
}

interface ChapterContent {
  bookId: string;
  chapterId: string;
  chapterTitle: string;
  content: string;
  index: number;
}

interface SummaryResult {
  summary: string;
  tokensUsed: number;
  tokensInput: number;
  tokensOutput: number;
  model: string;
  usedFallback?: boolean;
  originalModel?: string;
  fallbackModel?: string;
}

// Service interfaces
interface ChapterSummaryService {
  getSummary(bookId: string, chapterId: string, promptId: string): Promise<ChapterSummary | null>;
  saveSummary(summary: ChapterSummary): Promise<void>;
  regenerateSummary(bookId: string, chapterId: string, promptId: string): Promise<ChapterSummary>;
}
```

## API Key Management

For security reasons, LLM API keys are managed through a separate configuration system:

- API keys are stored in `src/services/llm/config/api-keys.ts`
- This file is excluded from version control via `.gitignore`
- A template file `api-keys.template.ts` is provided as a reference
- In development, keys can be directly used in the code
- In production, keys should be loaded from environment variables or a secure storage service

To set up API keys for development:
1. Copy `api-keys.template.ts` to `api-keys.ts`
2. Add your API keys to the appropriate provider in `api-keys.ts`
3. Never commit `api-keys.ts` to version control

For user-provided API keys, the system includes:
- UI for entering API keys in the settings panel
- Secure storage of user-provided keys
- Validation of API keys before saving

## Roadmap Considerations

Our architecture supports future expansion to:
1. Add more LLM providers beyond Minimax
2. Support book-level summarization
3. Implement Q&A features on selected text
4. Add support for podcast generation

## Implementation Notes

- Russian will be the default language for all prompts
- Users will be able to edit default prompts
- The feature will be accessible via the existing AI floating button
- All summarizations will be cached in SQLite with token usage tracking
- We'll implement robust error handling with retries and fallbacks
- The architecture will support the "bring your own API key" pattern

## TODO (Immediate Next Steps)
- [ ] Set up SQLite database schema
- [ ] Implement basic LLM service architecture
- [ ] Create chapter extraction utility
- [ ] Design and implement the UI flow

## Related Documents
- [Project Progress](/docs/PROGRESS.md)
- [Development Guidelines](/docs/development/guidelines.md) 