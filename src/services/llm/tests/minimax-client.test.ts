/**
 * Minimax Client Test
 * 
 * This demonstrates a well-designed TypeScript class for interfacing 
 * with the Minimax API, using proper typing and OO design principles.
 */

import axios, { AxiosInstance, AxiosResponse } from 'axios';
import dotenv from 'dotenv';
import { MinimaxClient } from '../clients/minimax-client';

// Load environment variables
dotenv.config();

// Type definitions
type Role = 'system' | 'user' | 'assistant';

interface Message {
  role: Role;
  content: string;
  name?: string;
}

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

/**
 * MinimaxClient Tests
 */

// Mock axios
jest.mock('axios', () => ({
  post: jest.fn()
}));

describe('MinimaxClient', () => {
  let client: MinimaxClient;
  const apiKey = 'test-api-key';
  const mockSuccessResponse = {
    data: {
      choices: [
        {
          message: {
            content: 'Test response content'
          }
        }
      ],
      usage: {
        total_tokens: 100,
        prompt_tokens: 50,
        completion_tokens: 50
      }
    },
    status: 200
  };

  beforeEach(() => {
    jest.clearAllMocks();
    client = new MinimaxClient({
      apiKey,
      model: 'MiniMax-Text-01',
      retryPolicy: {
        maxRetries: 2,
        initialDelayMs: 100
      }
    });
  });

  it('should create a client with default configuration', () => {
    const defaultClient = new MinimaxClient({ apiKey });
    expect(defaultClient).toBeDefined();
    expect(defaultClient['apiKey']).toBe(apiKey);
    expect(defaultClient['model']).toBe('MiniMax-Text-01'); // Default model
  });

  it('should send chat completion requests successfully', async () => {
    // Mock successful response
    (axios.post as jest.Mock).mockResolvedValue(mockSuccessResponse);

    // Execute request
    const messages = [
      { role: 'system', content: 'You are a helpful assistant' },
      { role: 'user', content: 'Hello, world!' }
    ];
    
    const result = await client.createChatCompletion(messages);
    
    // Verify response handling
    expect(result).toBeDefined();
    expect(result.text).toBe('Test response content');
    expect(result.tokenUsage.total).toBe(100);
    
    // Verify request format
    expect(axios.post).toHaveBeenCalledTimes(1);
    const [url, data, config] = (axios.post as jest.Mock).mock.calls[0];
    expect(url).toBe('https://api.minimax.chat/v1/text/chatcompletion_pro');
    expect(data.model).toBe('MiniMax-Text-01');
    expect(data.messages).toEqual(messages);
    expect(config.headers.Authorization).toBe('Bearer test-api-key');
  });

  it('should handle API errors gracefully', async () => {
    // Mock error response
    const errorResponse = new Error('API Error');
    (axios.post as jest.Mock).mockRejectedValue(errorResponse);
    
    // Execute request
    const messages = [
      { role: 'system', content: 'You are a helpful assistant' },
      { role: 'user', content: 'Hello, world!' }
    ];
    
    // Verify error handling
    await expect(client.createChatCompletion(messages)).rejects.toThrow('API Error');
    expect(axios.post).toHaveBeenCalledTimes(3); // Initial + 2 retries
  });
});

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
   * Generate a Russian haiku about a given theme
   */
  async generateRussianHaiku(theme: string): Promise<{
    haiku: string,
    usage: TokenUsage
  }> {
    const systemPrompt = 'Ты профессиональный поэт, специализирующийся на создании хайку на русском языке. ' +
      'Хайку - это традиционная японская форма поэзии, состоящая из трех строк.';
      
    const userPrompt = `Напиши хайку на русском языке на тему "${theme}". ` +
      'Хайку должно вызывать яркие образы и эмоции, связанные с природой и временем года.';
    
    const messages: Message[] = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt }
    ];
    
    const response = await this.createCompletion(messages, {
      temperature: 0.8,
      max_tokens: 100
    });
    
    return {
      haiku: response.choices[0].message.content,
      usage: response.usage
    };
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
  
  /**
   * Check if the API key is valid
   */
  async checkAPIKey(): Promise<boolean> {
    try {
      const messages: Message[] = [
        { role: 'system', content: 'You are a helpful assistant.' },
        { role: 'user', content: 'Hello!' }
      ];
      
      const response = await this.createCompletion(messages, { max_tokens: 5 });
      return response.base_resp.status_code === 0;
    } catch (error) {
      return false;
    }
  }
}

// Tests
describe('MinimaxClient', () => {
  let client: MinimaxClient;
  const apiKey = process.env.MINIMAX_API_KEY || '';
  
  beforeEach(() => {
    // Skip tests if API key is not set
    if (!apiKey) {
      console.warn('\x1b[33m%s\x1b[0m', 'No API key found in environment variables. Tests will be skipped.');
    }
    
    try {
      client = new MinimaxClient({ apiKey });
    } catch (error) {
      console.warn('Could not create client:', error);
    }
  });
  
  // Skip tests if no API key is available
  const conditionalTest = apiKey ? test : test.skip;
  
  conditionalTest('should create a client with default parameters', () => {
    expect(client).toBeDefined();
  });
  
  conditionalTest('should generate an answer to a simple question', async () => {
    const answer = await client.generateAnswer('What is the capital of France?');
    expect(answer).toBeDefined();
    expect(typeof answer).toBe('string');
    expect(answer.length).toBeGreaterThan(0);
    
    console.log('Answer:', answer);
  });
  
  conditionalTest('should generate a Russian haiku', async () => {
    const { haiku, usage } = await client.generateRussianHaiku('весна');
    
    expect(haiku).toBeDefined();
    expect(typeof haiku).toBe('string');
    expect(haiku.length).toBeGreaterThan(0);
    
    // Should contain Cyrillic characters
    expect(/[а-яА-ЯёЁ]/.test(haiku)).toBe(true);
    
    // Should have multiple lines
    const lines = haiku.split('\n');
    expect(lines.length).toBeGreaterThanOrEqual(3);
    
    console.log('Russian Haiku:');
    console.log(haiku);
    console.log('Usage:', usage);
  });
  
  conditionalTest('should validate API key', async () => {
    const isValid = await client.checkAPIKey();
    expect(isValid).toBe(true);
  });
  
  conditionalTest('should handle invalid API key', async () => {
    const invalidClient = new MinimaxClient({ 
      apiKey: 'invalid-api-key',
      maxRetries: 1  // Reduce retries for faster test
    });
    
    const isValid = await invalidClient.checkAPIKey();
    expect(isValid).toBe(false);
  });
}); 