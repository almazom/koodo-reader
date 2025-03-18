# Minimax API Integration Guide

This document provides implementation details and guidelines for integrating the Minimax API into Koodo Reader.

## Table of Contents

- [Introduction](#introduction)
- [API Configuration](#api-configuration)
- [Basic Usage](#basic-usage)
- [TypeScript Integration](#typescript-integration)
- [Handling Errors](#handling-errors)
- [Russian Language Support](#russian-language-support)
- [Testing](#testing)
- [Best Practices](#best-practices)

## Introduction

The Minimax API provides powerful natural language processing capabilities that can be integrated into Koodo Reader for features like chapter summarization, content generation, and more. This guide demonstrates how to connect to and use the Minimax API in both JavaScript and TypeScript.

## API Configuration

### API Endpoints

```javascript
// Production API endpoint
const BASE_URL = "https://api.minimaxi.chat/v1/text/chatcompletion_v2";

// Default model
const MODEL = "MiniMax-Text-01";
```

### Authentication

The API requires a Bearer token for authentication:

```javascript
const headers = {
  "Content-Type": "application/json",
  "Authorization": `Bearer ${API_KEY}`,
  "Accept": "application/json"
};
```

Store your API key securely using environment variables:

```javascript
// Load from environment variables
require('dotenv').config();
const API_KEY = process.env.MINIMAX_API_KEY;
```

## Basic Usage

### Simple Request (JavaScript)

```javascript
const axios = require('axios');

async function generateText(prompt) {
  const requestBody = {
    model: "MiniMax-Text-01",
    messages: [
      {
        role: "system",
        content: "You are a helpful assistant."
      },
      {
        role: "user",
        content: prompt
      }
    ],
    temperature: 0.7,
    max_tokens: 100
  };

  try {
    const response = await axios.post(
      "https://api.minimaxi.chat/v1/text/chatcompletion_v2",
      requestBody,
      {
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${process.env.MINIMAX_API_KEY}`
        }
      }
    );

    return response.data.choices[0].message.content;
  } catch (error) {
    console.error("Error generating text:", error.message);
    throw error;
  }
}
```

## TypeScript Integration

### Type Definitions

```typescript
// Message types
type Role = 'system' | 'user' | 'assistant';

interface Message {
  role: Role;
  content: string;
  name?: string;
}

// Request payload
interface CompletionRequest {
  model: string;
  messages: Message[];
  temperature?: number;
  max_tokens?: number;
  top_p?: number;
  frequency_penalty?: number;
  presence_penalty?: number;
  stop?: string[];
}

// Response types
interface CompletionResponseChoice {
  finish_reason: string;
  index: number;
  message: {
    content: string;
    role: string;
    name?: string;
  }
}

interface TokenUsage {
  total_tokens: number;
  prompt_tokens: number;
  completion_tokens: number;
  total_characters?: number;
}

interface CompletionResponse {
  id: string;
  choices: CompletionResponseChoice[];
  created: number;
  model: string;
  object: string;
  usage: TokenUsage;
  base_resp: {
    status_code: number;
    status_msg: string;
  };
}
```

### Reusable Client Class

```typescript
import axios, { AxiosInstance } from 'axios';

/**
 * MinimaxClient implements a strongly-typed API client for Minimax API
 */
class MinimaxClient {
  private apiKey: string;
  private baseUrl: string;
  private model: string;
  private axios: AxiosInstance;
  private retryPolicy: { maxRetries: number, initialDelay: number };

  /**
   * Create a new Minimax API client
   */
  constructor(options: {
    apiKey?: string, 
    baseUrl?: string, 
    model?: string,
    maxRetries?: number,
    initialDelay?: number
  } = {}) {
    this.apiKey = options.apiKey || process.env.MINIMAX_API_KEY || '';
    this.baseUrl = options.baseUrl || 'https://api.minimaxi.chat/v1/text/chatcompletion_v2';
    this.model = options.model || 'MiniMax-Text-01';
    this.retryPolicy = {
      maxRetries: options.maxRetries || 3,
      initialDelay: options.initialDelay || 1000
    };
    
    if (!this.apiKey) {
      throw new Error('Minimax API key is required');
    }
    
    // Create an Axios instance for making API requests
    this.axios = axios.create({
      baseURL: this.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`
      }
    });
  }
  
  /**
   * Generate a completion for the given messages
   */
  async createCompletion(
    messages: Message[],
    options: Partial<Omit<CompletionRequest, 'model' | 'messages'>> = {}
  ): Promise<CompletionResponse> {
    const request: CompletionRequest = {
      model: this.model,
      messages,
      ...options
    };
    
    return this.executeWithRetry(async () => {
      const response = await this.axios.post<CompletionResponse>('', request);
      return response.data;
    });
  }
  
  /**
   * Generate a single-turn response to a question
   */
  async generateAnswer(
    question: string, 
    systemPrompt: string = 'You are a helpful assistant.',
    options: Partial<Omit<CompletionRequest, 'model' | 'messages'>> = {}
  ): Promise<string> {
    const messages: Message[] = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: question }
    ];
    
    const response = await this.createCompletion(messages, options);
    return response.choices[0].message.content;
  }
  
  /**
   * Execute a function with retries
   */
  private async executeWithRetry<T>(fn: () => Promise<T>): Promise<T> {
    let lastError: Error | null = null;
    
    for (let attempt = 0; attempt < this.retryPolicy.maxRetries + 1; attempt++) {
      try {
        return await fn();
      } catch (error: any) {
        const delay = this.retryPolicy.initialDelay * Math.pow(2, attempt);
        console.warn(`Attempt ${attempt + 1}/${this.retryPolicy.maxRetries + 1} failed: ${error.message}. Retrying in ${delay}ms`);
        
        // Wait before retrying
        await new Promise(resolve => setTimeout(resolve, delay));
        
        lastError = error;
      }
    }
    
    throw lastError || new Error('All retry attempts failed');
  }
}
```

## Handling Errors

### Retry Logic

```typescript
/**
 * Execute a function with exponential backoff retry
 */
async function executeWithRetry<T>(
  fn: () => Promise<T>, 
  maxRetries: number = 3, 
  initialDelay: number = 1000
): Promise<T> {
  let lastError: Error | null = null;
  
  for (let attempt = 0; attempt < maxRetries + 1; attempt++) {
    try {
      return await fn();
    } catch (error: any) {
      const delay = initialDelay * Math.pow(2, attempt);
      console.warn(`Attempt ${attempt + 1}/${maxRetries + 1} failed: ${error.message}. Retrying in ${delay}ms`);
      
      // Wait before retrying
      await new Promise(resolve => setTimeout(resolve, delay));
      
      lastError = error;
    }
  }
  
  throw lastError || new Error('All retry attempts failed');
}
```

### Error Handling

```typescript
try {
  const response = await client.generateAnswer("What is the capital of France?");
  // Process response
} catch (error: any) {
  if (error.response) {
    // The request was made and the server responded with a status code
    // that falls out of the range of 2xx
    console.error("API Error:", error.response.data);
    console.error("Status:", error.response.status);
  } else if (error.request) {
    // The request was made but no response was received
    console.error("Network Error:", error.request);
  } else {
    // Something happened in setting up the request that triggered an Error
    console.error("Request Error:", error.message);
  }
}
```

## Russian Language Support

The Minimax API has excellent support for Russian language, which we use for generating haikus and potentially for summarization.

### Russian Haiku Generator

```typescript
/**
 * Generate a Russian haiku about a given theme
 */
async function generateRussianHaiku(theme: string): Promise<string> {
  const systemPrompt = 'Ты профессиональный поэт, специализирующийся на создании хайку на русском языке. ' +
    'Хайку - это традиционная японская форма поэзии, состоящая из трех строк.';
    
  const userPrompt = `Напиши хайку на русском языке на тему "${theme}". ` +
    'Хайку должно вызывать яркие образы и эмоции, связанные с природой и временем года.';
  
  const messages = [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: userPrompt }
  ];
  
  const response = await createCompletion(messages, {
    temperature: 0.8,
    max_tokens: 100
  });
  
  return response.choices[0].message.content;
}
```

## Testing

### Testing Connection

```typescript
async function testMinimaxConnection(): Promise<boolean> {
  try {
    const client = new MinimaxClient();
    const messages = [
      { role: 'system', content: 'You are a helpful assistant.' },
      { role: 'user', content: 'Hello!' }
    ];
    
    const response = await client.createCompletion(messages, { max_tokens: 5 });
    return response.base_resp.status_code === 0;
  } catch (error) {
    console.error("Connection test failed:", error);
    return false;
  }
}
```

## Best Practices

1. **API Key Security**
   - Store API keys in environment variables
   - Never commit API keys to version control
   - Use .env files for local development

2. **Error Handling**
   - Implement retry logic for transient errors
   - Provide meaningful error messages to users
   - Log detailed errors for debugging

3. **Performance Optimization**
   - Keep requests concise to minimize token usage
   - Use proper temperature settings based on the use case
   - Cache results when appropriate

4. **Response Validation**
   - Always validate response structure before accessing properties
   - Handle edge cases when choices array might be empty
   - Check status codes and error messages

5. **Integration with Koodo Reader**
   - Use the provider pattern for different LLM services
   - Implement a common interface for all LLM providers
   - Allow fallback to other providers if one fails

## Conclusion

The Minimax API provides powerful capabilities for text generation and understanding. With proper integration into Koodo Reader, we can enhance the reading experience with features like summaries, explanations, and more.

For more detailed information, see:
- [Minimax API Testing Results](/docs/features/minimax_api_testing.md)
- [Chapter Summarization Implementation Plan](/docs/features/minimax_implementation_plan.md) 