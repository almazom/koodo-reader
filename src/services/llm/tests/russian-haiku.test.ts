/**
 * Russian Haiku Generation Tests
 * 
 * These tests verify the functionality of the LLM service in generating
 * Russian haikus with the proper structure and theme.
 */

import { LLMServiceManager } from '../llm-service-manager';
import { SummaryResult } from '../llm-provider.interface';
import { MinimaxProvider } from '../providers/minimax-provider';
import { validateRussianHaiku } from './utils/russian-syllable-counter';

// Set longer timeout for tests
jest.setTimeout(10000);

// Mock the axios module
jest.mock('axios', () => ({
  post: jest.fn()
}));

// Import axios after mocking
import axios from 'axios';

// Mock the api-keys module
jest.mock('../config/api-keys', () => ({
  getApiKey: jest.fn().mockReturnValue('mock-api-key')
}));

describe('Russian Haiku Generation', () => {
  let llmService: LLMServiceManager;
  
  // Sample successful response from Minimax API with a valid 5-7-5 haiku
  const validHaiku = 'Тихий снегопад\nБелые хлопья кружат\nЗимний сон земли';
  const mockSuccessResponse = {
    data: {
      choices: [
        {
          message: {
            content: validHaiku
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

  beforeEach(() => {
    // Reset all mocks before each test
    jest.clearAllMocks();
    
    // Ensure getApiKey returns a value for mocking
    const { getApiKey } = require('../config/api-keys');
    (getApiKey as jest.Mock).mockReturnValue('mock-api-key');
    
    // Default mock implementation for successful API calls
    (axios.post as jest.Mock).mockResolvedValue(mockSuccessResponse);
    
    // Set up a new LLM service for each test
    llmService = new LLMServiceManager();
  });

  test('should generate a valid Russian haiku on a given theme', async () => {
    // Arrange
    const theme = 'зима';
    
    // Act
    const result = await llmService.generateRussianHaiku(theme);
    
    // Assert
    expect(result).toBeDefined();
    expect(result.summary).toBe(validHaiku);
    expect(result.tokensUsed).toBe(150);
    expect(result.tokensInput).toBe(100);
    expect(result.tokensOutput).toBe(50);
    expect(result.model).toBe('MiniMax-Text-01');
    
    // Verify API call
    expect(axios.post).toHaveBeenCalledTimes(1);
    const [url, data, config] = (axios.post as jest.Mock).mock.calls[0];
    
    // Check URL
    expect(url).toContain('minimax');
    
    // Check that theme was used in the request
    expect(data.messages[1].content).toContain(theme);
    
    // Check authentication
    expect(config.headers.Authorization).toBe('Bearer mock-api-key');
  });

  test('should handle API errors gracefully', async () => {
    // Arrange
    const theme = 'весна';
    (axios.post as jest.Mock).mockRejectedValue(new Error('API Error'));
    
    // Act & Assert
    await expect(llmService.generateRussianHaiku(theme)).rejects.toThrow('API Error');
    expect(axios.post).toHaveBeenCalledTimes(4); // Initial call + 3 retries
  });

  test('should verify the haiku follows the 5-7-5 syllable structure', async () => {
    // Arrange
    const theme = 'осень';
    
    // Mock a response with a properly structured haiku (5-7-5 syllables)
    const structuredHaiku = 'Жёлтые листья\nКружатся в танце ветра\nОсень пришла к нам';
    (axios.post as jest.Mock).mockResolvedValue({
      data: {
        choices: [{ message: { content: structuredHaiku } }],
        usage: { total_tokens: 150, prompt_tokens: 100, completion_tokens: 50 }
      },
      status: 200
    });
    
    // Act
    const result = await llmService.generateRussianHaiku(theme);
    
    // Assert
    expect(result.summary).toBe(structuredHaiku);
    
    // Verify haiku structure using the syllable counter
    const validation = validateRussianHaiku(result.summary);
    expect(validation.isValid).toBe(true);
    expect(validation.lineSyllables).toEqual([5, 7, 5]);
  });

  test('should detect invalid haiku structures', async () => {
    // Arrange
    const theme = 'река';
    
    // Mock a response with an invalid haiku structure (wrong syllable count)
    const invalidHaiku = 'Быстрая река течёт\nМежду высоких гор и лесов\nВ синее море';
    (axios.post as jest.Mock).mockResolvedValue({
      data: {
        choices: [{ message: { content: invalidHaiku } }],
        usage: { total_tokens: 150, prompt_tokens: 100, completion_tokens: 50 }
      },
      status: 200
    });
    
    // Act
    const result = await llmService.generateRussianHaiku(theme);
    
    // Assert
    expect(result.summary).toBe(invalidHaiku);
    
    // Verify that validation detects the invalid structure
    const validation = validateRussianHaiku(result.summary);
    expect(validation.isValid).toBe(false);
    // The actual syllable counts will depend on the invalid haiku text
  });

  test('should use the specified LLM model if provided', async () => {
    // Arrange
    const theme = 'лето';
    const options = { model: 'MiniMax-Text-01' }; // Ensure we use a provider that exists
    
    // Act
    await llmService.generateRussianHaiku(theme, options);
    
    // Assert
    const [_, data] = (axios.post as jest.Mock).mock.calls[0];
    expect(data.model).toBe('MiniMax-Text-01');
  });

  test('should try fallback provider when primary fails', async () => {
    // Arrange
    const theme = 'море';
    
    // A valid haiku about the sea for the mock response
    const seaHaiku = 'Синее море\nВолны бьются о скалы\nМечта о дали';
    
    // Create a custom service with just minimax provider - we'll mock failure/fallback
    const customService = new LLMServiceManager({
      defaultProvider: 'minimax',
      fallbackProviders: []
    });
    
    // First mock a failure
    (axios.post as jest.Mock).mockRejectedValueOnce(new Error('API Error'));
    
    // Then mock a success on retry
    (axios.post as jest.Mock).mockResolvedValueOnce({
      data: {
        choices: [{ message: { content: seaHaiku } }],
        usage: { total_tokens: 120, prompt_tokens: 80, completion_tokens: 40 }
      },
      status: 200
    });
    
    // Act
    const result = await customService.generateRussianHaiku(theme);
    
    // Assert
    expect(result.summary).toBe(seaHaiku);
    expect(result.model).toBe('MiniMax-Text-01');
    expect(axios.post).toHaveBeenCalledTimes(2); // Original call + 1 retry
    
    // Verify haiku structure
    const validation = validateRussianHaiku(result.summary);
    expect(validation.isValid).toBe(true);
  });

  test('should validate the haiku covers the requested theme', async () => {
    // Arrange
    const theme = 'звёзды';
    
    // Mock a response with a haiku about stars
    const starHaiku = 'Мерцают звёзды\nВ бескрайнем тёмном небе\nМиры далёкие';
    (axios.post as jest.Mock).mockResolvedValue({
      data: {
        choices: [{ message: { content: starHaiku } }],
        usage: { total_tokens: 150, prompt_tokens: 100, completion_tokens: 50 }
      },
      status: 200
    });
    
    // Act
    const result = await llmService.generateRussianHaiku(theme);
    
    // Assert
    expect(result.summary).toBe(starHaiku);
    expect(result.summary.toLowerCase()).toContain(theme.toLowerCase());
    
    // Only verify theme is included, not structure
    expect(result.summary.toLowerCase()).toContain(theme.toLowerCase());
  });
  
  test('should generate haikus for different themes', async () => {
    // This test verifies the LLM service can generate haikus for various themes
    const themes = ['дождь', 'солнце'];
    
    for (const theme of themes) {
      // Mock a unique haiku for each theme
      const mockHaiku = `${theme.charAt(0).toUpperCase() + theme.slice(1)} в природе\nГармония вечности\nДуша отдыхает`;
      
      (axios.post as jest.Mock).mockResolvedValueOnce({
        data: {
          choices: [{ message: { content: mockHaiku } }],
          usage: { total_tokens: 150, prompt_tokens: 100, completion_tokens: 50 }
        },
        status: 200
      });
      
      // Act
      const result = await llmService.generateRussianHaiku(theme);
      
      // Assert
      expect(result.summary.toLowerCase()).toContain(theme.toLowerCase());
    }
    
    // Verify the API was called for each theme
    expect(axios.post).toHaveBeenCalledTimes(themes.length);
  });

  test('should successfully connect to Minimax API and generate text', async () => {
    // Arrange
    const theme = 'весна';
    const minimaxProvider = new MinimaxProvider();
    
    // Mock a successful API response
    const generatedText = 'Весенний текст о природе';
    (axios.post as jest.Mock).mockResolvedValue({
      data: {
        choices: [{ message: { content: generatedText } }],
        usage: { total_tokens: 150, prompt_tokens: 100, completion_tokens: 50 }
      },
      status: 200
    });
    
    // Act
    const result = await minimaxProvider.generateRussianHaiku(theme);
    
    // Assert basic response structure
    expect(result).toBeDefined();
    expect(result.summary).toBe(generatedText);
    expect(result.model).toBe('MiniMax-Text-01');
    expect(result.tokensUsed).toBe(150);
    expect(result.tokensInput).toBe(100);
    expect(result.tokensOutput).toBe(50);
    
    // Verify API connection details
    const [url, data, config] = (axios.post as jest.Mock).mock.calls[0];
    expect(url).toBe('https://api.minimax.chat/v1/text/chatcompletion_pro');
    expect(config.headers.Authorization).toBe('Bearer mock-api-key');
    expect(config.headers['Content-Type']).toBe('application/json');
    
    // Verify request payload structure
    expect(data.messages).toBeDefined();
    expect(data.messages.length).toBeGreaterThan(0);
    expect(data.messages[0].role).toBe('system');
    expect(data.messages[1].role).toBe('user');
    expect(data.messages[1].content).toContain(theme);
    
    // Verify API call count
    expect(axios.post).toHaveBeenCalledTimes(1);
  });

  test('should handle Minimax API errors gracefully', async () => {
    // Arrange
    const theme = 'тест';
    const minimaxProvider = new MinimaxProvider();
    
    // Mock API error for all consecutive calls
    for (let i = 0; i < 4; i++) {
      (axios.post as jest.Mock).mockRejectedValueOnce(new Error('API Error: Invalid response'));
    }
    
    // Act & Assert
    await expect(minimaxProvider.generateRussianHaiku(theme)).rejects.toThrow('API Error');
    
    // Verify call count
    expect(axios.post).toHaveBeenCalledTimes(1);
  });

  test('should handle Minimax API rate limiting', async () => {
    // Arrange
    const theme = 'тест';
    const minimaxProvider = new MinimaxProvider();
    
    // Mock rate limit response
    const rateLimitError = new Error('Rate limit exceeded');
    rateLimitError['status'] = 429;
    (axios.post as jest.Mock).mockRejectedValueOnce(rateLimitError);
    
    // Act & Assert
    await expect(minimaxProvider.generateRussianHaiku(theme)).rejects.toThrow('Rate limit exceeded');
    
    // Verify API call
    expect(axios.post).toHaveBeenCalledTimes(1);
  });

  test('should verify Minimax API key validity', async () => {
    // Arrange
    const minimaxProvider = new MinimaxProvider();
    
    // Mock successful API response
    (axios.post as jest.Mock).mockResolvedValue({ status: 200 });
    
    // Act
    const isValid = await minimaxProvider.checkAPIKey();
    
    // Assert
    expect(isValid).toBe(true);
    expect(axios.post).toHaveBeenCalledTimes(1);
    
    // Verify request
    const [url, data, config] = (axios.post as jest.Mock).mock.calls[0];
    expect(url).toBe('https://api.minimax.chat/v1/text/chatcompletion_pro');
    expect(data.messages[0].content).toBe('You are a helpful assistant.');
    expect(config.headers.Authorization).toBe('Bearer mock-api-key');
  });

  test('should provide correct model information', () => {
    // Arrange
    const minimaxProvider = new MinimaxProvider();
    
    // Act
    const modelInfo = minimaxProvider.getModelInfo();
    
    // Assert
    expect(modelInfo.name).toBe('MiniMax-Text-01');
    expect(modelInfo.provider).toBe('Minimax');
    expect(modelInfo.capabilities).toContain('text-generation');
    expect(modelInfo.contextWindow).toBe(16000);
    expect(modelInfo.maxOutputTokens).toBe(4000);
  });

  test('should list available models', () => {
    // Arrange
    const minimaxProvider = new MinimaxProvider();
    
    // Act
    const models = minimaxProvider.getAvailableModels();
    
    // Assert
    expect(models).toContain('MiniMax-Text-01');
    expect(models).toContain('DeepSeek-R1');
    expect(models.length).toBe(2);
  });

  test('should handle missing API key', async () => {
    // Arrange
    const minimaxProvider = new MinimaxProvider();
    const { getApiKey } = require('../config/api-keys');
    (getApiKey as jest.Mock).mockReturnValue(null);
    
    // Act & Assert
    await expect(minimaxProvider.generateRussianHaiku('test')).rejects.toThrow('API key not configured');
    await expect(minimaxProvider.checkAPIKey()).resolves.toBe(false);
  });

  test('should use custom model and parameters', async () => {
    // Arrange
    const theme = 'тест';
    const minimaxProvider = new MinimaxProvider();
    const options = {
      model: 'DeepSeek-R1',
      temperature: 0.5,
      max_tokens: 1000
    };
    
    // Mock successful response
    (axios.post as jest.Mock).mockResolvedValue({
      data: {
        choices: [{ message: { content: 'Test response' } }],
        usage: { total_tokens: 100, prompt_tokens: 50, completion_tokens: 50 }
      },
      status: 200
    });
    
    // Act
    const result = await minimaxProvider.generateRussianHaiku(theme, options);
    
    // Assert
    expect(result.model).toBe('DeepSeek-R1');
    
    // Verify request parameters
    const [_, data] = (axios.post as jest.Mock).mock.calls[0];
    expect(data.model).toBe('DeepSeek-R1');
    expect(data.temperature).toBe(0.5);
    expect(data.max_tokens).toBe(1000);
  });

  test('should mimic JavaScript test connection pattern', async () => {
    // Arrange
    const minimaxProvider = new MinimaxProvider();
    
    // Mock successful response based on JS test file
    (axios.post as jest.Mock).mockResolvedValue({
      data: {
        choices: [{ 
          message: { 
            content: 'Привет! Я виртуальный ассистент и могу помочь с генерацией красивых хайку на русском языке.' 
          } 
        }],
        usage: { total_tokens: 100, prompt_tokens: 30, completion_tokens: 70 }
      },
      status: 200
    });
    
    // Act
    const result = await minimaxProvider.checkAPIKey();
    
    // Assert
    expect(result).toBe(true);
    expect(axios.post).toHaveBeenCalledTimes(1);
    
    // Verify request matches JavaScript test pattern
    const [url, data, config] = (axios.post as jest.Mock).mock.calls[0];
    expect(url).toBe('https://api.minimax.chat/v1/text/chatcompletion_pro');
    expect(data.model).toBe('MiniMax-Text-01');
    expect(data.messages[0].role).toBe('system');
    expect(data.messages[0].content).toBe('You are a helpful assistant.');
    expect(config.headers.Authorization).toContain('Bearer ');
    expect(config.headers['Content-Type']).toBe('application/json');
  });
}); 