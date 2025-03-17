# Storage & Persistence Requirements

## Overview

The Storage & Persistence requirements define how LLM-generated content will be stored, managed, and synchronized within Koodo Reader. This document outlines the detailed requirements for data models, storage mechanisms, caching strategies, and synchronization approaches.

## User Stories

1. As a reader, I want my generated summaries and Q&A interactions to persist between sessions, so I don't lose valuable insights.
2. As a mobile user, I want efficient storage management for podcast files, so I don't exhaust my device storage.
3. As a user with multiple devices, I want my LLM-generated content to synchronize, so I have consistent access across platforms.
4. As a privacy-conscious user, I want control over what LLM data is stored and for how long, so I can manage my digital footprint.
5. As a frequent user, I want efficient caching of common LLM operations, so I don't incur unnecessary API costs for repeated requests.

## Functional Requirements

### Data Persistence

- **F-STO-01**: The system shall persistently store the following LLM-generated content:
  - Chapter and book summaries
  - Q&A interactions and conversation history
  - Generated podcast audio files
  - Content analysis (character lists, timelines, etc.)
  - User preferences for LLM features

- **F-STO-02**: The system shall associate stored content with:
  - Specific books (by unique identifier)
  - Specific chapters/sections where applicable
  - Creation timestamps
  - Content type identifiers
  - Version information

- **F-STO-03**: The system shall implement version control for stored content:
  - Track content versions based on source changes
  - Prevent overwriting newer content with older versions
  - Manage conflicts during synchronization
  - Provide version history where appropriate

- **F-STO-04**: The system shall enable content export and import:
  - Export summaries as text files
  - Export Q&A sessions as text or structured formats
  - Export podcast files as standard audio formats
  - Import previously exported content

### Storage Management

- **F-STO-05**: The system shall provide storage management controls:
  - Display storage usage by content type
  - Allow selective deletion of content
  - Support automatic cleanup policies
  - Warn about storage limitations
  - Provide optimization recommendations

- **F-STO-06**: The system shall implement storage quotas and limits:
  - Configurable maximum storage allocation
  - Content-type-specific quotas
  - Priority settings for storage allocation
  - Automatic cleanup based on age/usage
  - Warning notifications when approaching limits

- **F-STO-07**: The system shall optimize storage efficiency:
  - Compress text content where beneficial
  - Use appropriate audio compression
  - Prevent duplicate storage of identical content
  - Implement reference counting for shared resources
  - Support on-demand regeneration vs. storage tradeoffs

### Synchronization

- **F-STO-08**: The system shall support content synchronization:
  - Selective synchronization by content type
  - Bandwidth-aware synchronization policies
  - Conflict resolution strategies
  - Background synchronization
  - Synchronization status indicators

- **F-STO-09**: The system shall handle offline operations:
  - Provide access to cached content when offline
  - Queue operations for execution when online
  - Track modified content for synchronization
  - Detect and resolve conflicts after reconnection
  - Prioritize synchronization of critical content

## Non-Functional Requirements

### Performance

- **NF-STO-01**: The system shall provide efficient data access:
  - Retrieve common summaries in <100ms
  - Load Q&A history in <200ms
  - Access content metadata in <50ms
  - Stream audio content without buffering delays
  - Maintain responsiveness during storage operations

- **NF-STO-02**: The system shall optimize background storage operations:
  - Defer non-critical write operations
  - Batch related storage updates
  - Implement progressive loading for large content sets
  - Minimize blocking operations on the main thread
  - Prioritize read operations over maintenance tasks

### Reliability

- **NF-STO-03**: The system shall protect against data loss:
  - Implement transactional updates where appropriate
  - Provide automatic backups of critical content
  - Handle storage errors gracefully
  - Recover from corrupted data when possible
  - Prevent data loss during synchronization

- **NF-STO-04**: The system shall maintain data integrity:
  - Validate data before storage
  - Maintain referential integrity between related content
  - Prevent orphaned data
  - Detect and repair inconsistencies
  - Enforce schema constraints

### Security and Privacy

- **NF-STO-05**: The system shall protect sensitive data:
  - Encrypt API keys and credentials
  - Respect user privacy preferences
  - Implement secure deletion when requested
  - Provide data portability options
  - Support privacy-preserving synchronization

## Technical Requirements

### Database Structure

- **T-STO-01**: The system shall extend the existing IndexedDB database:
  - Create new object stores for LLM content
  - Define appropriate indexes for efficient queries
  - Implement schema versioning for upgrades
  - Maintain backward compatibility
  - Support the existing database service architecture

- **T-STO-02**: The system shall define the following object stores:
  - **llm_summaries**: For chapter and book summaries
  - **llm_conversations**: For Q&A interactions
  - **llm_podcasts**: For podcast metadata (audio files stored separately)
  - **llm_content_analysis**: For character lists, timelines, etc.
  - **llm_settings**: For user preferences and API configurations

### Data Models

- **T-STO-03**: The system shall implement the following data models:

  ```typescript
  interface LLMSummary {
    id: string;              // Unique identifier
    bookKey: string;         // Reference to book
    chapterIndex?: number;   // Chapter reference (null for whole book)
    type: 'concise' | 'detailed' | 'bullet' | 'character'; // Summary type
    content: string;         // The summary text
    metadata: {
      wordCount: number,     // Original word count
      timestamp: number,     // Creation time
      model: string,         // LLM model used
      promptVersion: string  // Prompt version used
    }
  }

  interface LLMConversation {
    id: string;              // Unique identifier
    bookKey: string;         // Reference to book
    chapterIndex?: number;   // Chapter reference (if applicable)
    title: string;           // Auto-generated conversation title
    messages: {
      role: 'user' | 'assistant',
      content: string,
      timestamp: number,
      contextRange?: {       // Text selection context
        start: number,
        end: number,
        text: string
      }
    }[];
    metadata: {
      timestamp: number,     // Creation time
      lastUpdated: number,   // Last message time
      model: string          // LLM model used
    }
  }

  interface LLMPodcast {
    id: string;              // Unique identifier
    bookKey: string;         // Reference to book
    chapterIndices: number[]; // Chapters included
    audioUrl: string;        // Local URL to audio file
    duration: number;        // Duration in seconds
    metadata: {
      timestamp: number,     // Creation time
      format: string,        // Audio format
      voices: string[],      // Voices used
      sizeBytes: number,     // File size
      quality: string        // Quality setting used
    }
  }

  interface LLMContentAnalysis {
    id: string;              // Unique identifier
    bookKey: string;         // Reference to book
    type: 'characters' | 'timeline' | 'locations' | 'themes'; // Analysis type
    content: object;         // Structured content appropriate to type
    metadata: {
      timestamp: number,     // Creation time
      model: string,         // LLM model used
      promptVersion: string  // Prompt version used
    }
  }
  ```

### Storage Implementation

- **T-STO-04**: The system shall extend the DatabaseService with LLM-specific methods:
  - CRUD operations for each LLM content type
  - Batch operations for efficiency
  - Query methods with filtering
  - Index-based lookups
  - Pagination support for large datasets

- **T-STO-05**: The system shall implement appropriate indexing:
  - Primary key indices for direct lookup
  - Book key indices for all content types
  - Chapter indices where applicable
  - Timestamp indices for ordering/cleanup
  - Type indices for content filtering

### Caching Strategy

- **T-STO-06**: The system shall implement efficient caching:
  - In-memory cache for frequently accessed content
  - Cache invalidation based on changes
  - Preloading of likely-needed content
  - Cache size limits based on device capabilities
  - Cache prioritization based on usage patterns

- **T-STO-07**: The system shall optimize API usage through caching:
  - Store results of expensive LLM operations
  - Implement content hash for detecting identical requests
  - Cache prompt-result pairs where appropriate
  - Implement time-based cache expiration policies
  - Support forced refresh for outdated cache entries

### File Storage

- **T-STO-08**: The system shall manage audio file storage:
  - Store files in appropriate browser storage
  - Implement garbage collection for unused files
  - Support streaming access for playback
  - Optimize storage formats based on usage
  - Handle large file limitations

## Implementation Considerations

### Database Schema Design

The database schema should consider:

1. **Performance**: Indexes on frequently queried fields
2. **Flexibility**: Schema that accommodates future features
3. **Compatibility**: Smooth upgrades from existing database versions
4. **Size efficiency**: Appropriate data types and normalization
5. **Query patterns**: Optimized for common access patterns

### Storage Strategy by Content Type

| Content Type | Storage Approach | Sync Priority | Cleanup Strategy |
|--------------|------------------|---------------|------------------|
| Summaries | Full text in IndexedDB | High | Manual deletion or age-based |
| Q&A History | Full text with pagination | Medium | Age-based or conversation limit |
| Podcasts | Metadata in IndexedDB, files in FileSystem | Low | Size-based with LRU policy |
| Content Analysis | Structured data in IndexedDB | Medium | Manual deletion |
| Settings | Small data in IndexedDB | High | Retain until explicitly changed |

### Synchronization Approach

For multi-device scenarios:

1. **Content addressing**: Use deterministic IDs based on content
2. **Merge strategy**: Last-write-wins with timestamps
3. **Conflict resolution**: Retain both versions when true conflict detected
4. **Sync granularity**: Individual content items rather than full stores
5. **Bandwidth optimization**: Delta synchronization where possible

### Migration Planning

When upgrading database schema:

1. Define proper version upgrade paths
2. Implement data migration during schema upgrades
3. Provide fallback access to older formats
4. Validate data integrity after migration
5. Allow rollback capability for failed migrations

## Acceptance Criteria

1. All LLM-generated content persists correctly between application sessions
2. Storage operations maintain application responsiveness
3. Content is correctly associated with specific books and chapters
4. Storage management controls function as specified
5. Data integrity is maintained during synchronization
6. Storage limits and quotas function correctly
7. Database upgrades preserve existing content
8. Export and import functionality works as specified 