# Chapter Summarization Requirements

## Overview

Chapter summarization is the highest priority LLM feature for Koodo Reader, enabling users to generate concise summaries of book chapters. This feature leverages the existing book structure (table of contents, chapters, subchapters) to provide valuable context while reading complex texts.

## User Stories

1. As a reader of complex philosophical texts, I want to get a summary of the current chapter, so I can better understand difficult concepts.
2. As a student, I want to summarize chapters in textbooks, so I can review material efficiently.
3. As a reader who hasn't opened a book for a while, I want to read summaries of previous chapters, so I can refresh my memory before continuing.
4. As a researcher, I want to identify key concepts in each chapter, so I can quickly find relevant information.

## Functional Requirements

### Core Functionality

- **F-CSUM-01**: The system shall provide on-demand chapter summarization:
  - Users must explicitly request summary generation through a dedicated button/control
  - Summaries should not be automatically generated without user action
  - Generation process should show appropriate progress indicators

- **F-CSUM-02**: The system shall clearly indicate summarization status in the UI:
  - Visual indicators showing which chapters have existing summaries
  - Clear distinction between chapters with and without summaries
  - Status indicators for in-progress summarization

- **F-CSUM-03**: The system shall enable users to:
  - Generate new summaries for chapters
  - Read previously generated summaries
  - Regenerate summaries for a chapter (replacing previous summary)
  - Navigate between chapter content and summaries easily

- **F-CSUM-04**: The system shall extract appropriate chapter content:
  - Identify chapter boundaries correctly
  - Handle various book formats and structures
  - Process chapter content including headings, paragraphs, and other elements
  - Exclude non-relevant content (page numbers, footnotes, etc. when appropriate)

### User Interface

- **F-CSUM-05**: The system shall provide intuitive access to chapter summarization:
  - Integration with chapter navigation UI
  - Button/control in appropriate location based on existing UI patterns
  - Consistent placement across the application

- **F-CSUM-06**: The system shall display summaries in a readable format:
  - Clear typography consistent with app design
  - Appropriate formatting for different summary elements
  - Scrollable container for longer summaries
  - Ability to copy summary text

- **F-CSUM-07**: The system shall display progress indicators during summarization:
  - Visual indicator showing operation in progress
  - Estimate of completion time for longer chapters
  - Cancel option for in-progress operations

### Storage and Management

- **F-CSUM-08**: The system shall persistently store generated summaries:
  - Associated with specific book and chapter
  - Accessible across reading sessions
  - Available offline after generation
  - Properly versioned if regenerated

- **F-CSUM-09**: The system shall provide management options:
  - Delete specific summaries
  - View information about generation (date, model used, etc.)
  - Export summaries (as text)

## Non-Functional Requirements

### Performance

- **NF-CSUM-01**: The system shall generate summaries within reasonable timeframes:
  - Short chapters (<5,000 words): within 15 seconds
  - Medium chapters (5,000-15,000 words): within 30 seconds
  - Long chapters (>15,000 words): within 60 seconds
  - Actual performance may vary based on API provider and connection speed

- **NF-CSUM-02**: The system shall remain responsive during summarization:
  - UI should not freeze during API calls
  - Reading experience should not be interrupted
  - Background processing should be used where appropriate

### Mobile Optimization

- **NF-CSUM-03**: The system shall optimize for mobile experience:
  - Touch-friendly controls
  - Appropriate use of screen space on smaller devices
  - Battery and data usage considerations
  - Special focus on Android optimization (primary target platform)

### Reliability

- **NF-CSUM-04**: The system shall handle failures gracefully:
  - Provide clear error messages for API failures
  - Offer retry options for failed operations
  - Save partial progress where possible
  - Prevent data loss during interruptions

## Technical Requirements

### LLM Integration

- **T-CSUM-01**: The system shall integrate with configured LLM providers:
  - Support all providers specified in API integration requirements
  - Handle provider-specific prompt formatting
  - Process responses appropriately for each provider
  - Apply appropriate parameters for summary generation

- **T-CSUM-02**: The system shall implement effective prompt engineering:
  - Clear instructions for summary generation
  - Context provision for chapter content
  - Format specifications for consistent output
  - Guardrails against hallucination

### Text Processing

- **T-CSUM-03**: The system shall process chapter text effectively:
  - Handle HTML/formatting in EPUB content
  - Manage special characters and symbols
  - Process structured content appropriately
  - Extract key information from complex layouts

- **T-CSUM-04**: The system shall implement chunking strategies for long chapters:
  - Divide long text into manageable segments
  - Preserve context between chunks
  - Recombine chunk summaries coherently
  - Handle token limitations of different providers

### Database Integration

- **T-CSUM-05**: The system shall extend the database schema for summaries:
  - Create appropriate tables/object stores
  - Define efficient indexing strategy
  - Implement versioning approach
  - Support efficient queries for summary retrieval

## Implementation Considerations

### Prompt Template

For effective chapter summarization, the following prompt template is recommended:

```
Task: Summarize the following chapter from "{book_title}".

Chapter Title: {chapter_title}

Chapter Content:
{chapter_content}

Instructions:
1. Create a concise summary that captures the main ideas, key concepts, and important points from this chapter.
2. Focus on philosophical concepts and their relationships.
3. Include any important terminology defined in this chapter.
4. Maintain factual accuracy and do not introduce information not present in the text.
5. Format the summary in clear paragraphs.

Output:
```

### UI Integration Points

Based on existing Koodo Reader UI patterns, the following integration points are recommended:

1. **Chapter Navigation** - Add summary indicator icon next to chapters
2. **Reader Toolbar** - Add summarize button in appropriate location
3. **Context Menu** - Add summarize option in chapter context menu
4. **TOC Panel** - Integrate summary indicators in table of contents

### Mobile-First Considerations

For optimal mobile experience:

1. Place controls within thumb-friendly zones
2. Use appropriate font sizes for readability on small screens
3. Implement collapsible UI elements to maximize reading space
4. Provide clear touch targets for all interactive elements
5. Consider offline usage scenarios for mobile users

## Acceptance Criteria

1. Users can generate summaries for individual chapters via intuitive UI
2. Summaries are stored persistently and available across sessions
3. Visual indicators clearly show which chapters have summaries
4. Summaries maintain factual accuracy and capture key chapter concepts
5. The feature works effectively on mobile devices, especially Android
6. Users can regenerate summaries if desired
7. Performance meets specified requirements across different chapter lengths 