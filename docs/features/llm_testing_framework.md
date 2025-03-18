# LLM Testing Framework with Russian Haiku Generation

## Overview

This document describes the testing framework for validating the LLM (Large Language Model) integration in Koodo Reader. The framework uses Russian haiku generation as a lightweight but comprehensive way to test the LLM API interface, focusing on both technical correctness and semantic capabilities of the models.

## Why Russian Haiku?

Russian haiku generation was selected as our primary testing approach for several reasons:

1. **Structured Output Validation**: Haiku follows a specific structure (5-7-5 syllables) that can be programmatically verified
2. **Cross-cultural Linguistic Challenge**: Testing LLM capabilities in Russian tests multilingual support
3. **Lightweight API Calls**: Haiku generation requires minimal tokens, making tests faster and cost-effective
4. **Creative Task**: Tests both technical API integration and creative LLM capabilities
5. **Verifiable Quality**: The theme-based generation allows for semantic validation of results

## Core Components

The testing framework consists of several key components:

### 1. LLM Provider Interface

```typescript
export interface LLMProvider {
  generateSummary(text: string, options: LLMOptions): Promise<SummaryResult>;
  generateRussianHaiku(theme: string, options?: LLMOptions): Promise<SummaryResult>;
  checkAPIKey(): Promise<boolean>;
  getModelInfo(): LLMModelInfo;
  getAvailableModels(): string[];
}
```

This interface defines the contract that all LLM providers must implement, including a dedicated method for Russian haiku generation.

### 2. Minimax Provider Implementation

The Minimax provider implements the LLM interface with specialized Russian haiku generation capabilities:

```typescript
async generateRussianHaiku(theme: string, options?: LLMOptions): Promise<SummaryResult> {
  // Implementation includes specialized prompting for Russian haiku
  const systemMessage = 'Ты профессиональный поэт, специализирующийся на создании хайку на русском языке...';
  const userMessage = `Напиши хайку на русском языке на тему "${theme}"...`;
  
  // API call and response handling
}
```

### 3. Russian Syllable Counter

A specialized utility for validating haiku structure:

```typescript
export function validateRussianHaiku(haiku: string): {
  isValid: boolean;
  lineSyllables: number[];
  description: string;
}
```

This function analyzes Russian text to count syllables in each line and validate the 5-7-5 structure.

### 4. Comprehensive Test Suite

Tests cover multiple aspects of the LLM integration:

- Basic haiku generation
- Theme-based content validation
- Structural validation (5-7-5 syllables)
- Error handling and retries
- Provider fallback mechanisms
- Model selection

## Test Cases

The test suite includes the following key test cases:

1. **Basic Haiku Generation**: Verify the API can generate haiku on a given theme
2. **Syllable Structure**: Validate haiku follows the 5-7-5 structure
3. **Invalid Structure Detection**: Detect when a generated haiku doesn't follow the structure
4. **Error Handling**: Gracefully handle API errors with appropriate retries
5. **Provider Fallback**: Test fallback to alternate providers when primary fails
6. **Theme Relevance**: Verify generated haiku is semantically related to the theme
7. **Multi-Theme Support**: Generate haikus on various themes to test flexibility

## Usage

To run the tests:

```bash
npm test -- src/services/llm/tests/russian-haiku.test.ts
```

The tests use Jest's mocking capabilities to simulate API calls without making actual network requests.

## Mock Implementation

API calls are mocked to simulate various scenarios:

```typescript
jest.mock('axios', () => ({
  post: jest.fn()
}));

// Mock successful response
const mockSuccessResponse = {
  data: {
    choices: [
      {
        message: {
          content: 'Тихий снегопад\nБелые хлопья кружат\nЗимний сон земли'
        }
      }
    ],
    usage: {
      total_tokens: 150,
      prompt_tokens: 100,
      completion_tokens: 50
    }
  },
  status: 200
};

// Set up mock
(axios.post as jest.Mock).mockResolvedValue(mockSuccessResponse);
```

## Expanding the Framework

This testing framework serves as a foundation for testing all LLM functionality in Koodo Reader. Future expansions will include:

1. **Chapter Summarization Testing**: Validating longer text summarization
2. **Question Answering Tests**: Verifying Q&A capabilities using predefined questions
3. **Cross-Provider Testing**: Ensuring consistent behavior across multiple LLM providers
4. **Performance Testing**: Measuring response times and token usage

## Roadmap

- [ ] Add more comprehensive tests for error scenarios
- [ ] Implement actual API integration tests (for development use only)
- [ ] Create visualization tools for test results
- [ ] Add more sophisticated linguistic validation for Russian text
- [ ] Expand to testing additional languages 