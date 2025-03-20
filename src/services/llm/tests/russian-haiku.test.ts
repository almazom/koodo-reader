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
    // Reset mocks
    jest.clearAllMocks();
    
    // Create a new service instance with mock provider
    const provider = new MinimaxProvider();
    llmService = new LLMServiceManager({
      providers: [provider],
      defaultProvider: 'minimax',
      retryPolicy: {
        maxRetries: 2,
        initialDelayMs: 100
      }
    });
  });

  it('should generate a valid Russian haiku with 5-7-5 syllable structure', async () => {
    // Arrange
    (axios.post as jest.Mock).mockResolvedValue(mockSuccessResponse);
    
    // Act
    const result = await llmService.generateRussianHaiku('winter');
    
    // Assert
    expect(result).toBeDefined();
    expect(result.summary).toBe(validHaiku);
    expect(result.tokensUsed).toBe(150);
    
    // Validate haiku structure
    const validation = validateRussianHaiku(result.summary);
    expect(validation.isValid).toBe(true);
    expect(validation.lineSyllables).toEqual([5, 7, 5]);

    // Verify API call
    expect(axios.post).toHaveBeenCalledTimes(1);
  });

  it('should handle API errors gracefully', async () => {
    // Arrange
    const errorResponse = {
      response: {
        status: 500,
        data: { error: 'Internal Server Error' }
      }
    };
    
    (axios.post as jest.Mock).mockRejectedValue(errorResponse);
    
    // Act & Assert
    try {
      await llmService.generateRussianHaiku('spring');
      fail('Should have thrown an error');
    } catch (err) {
      expect(err).toBeDefined();
    }
  });

  it('should validate proper 5-7-5 structure in haikus', () => {
    // Valid 5-7-5 structure
    const valid = validateRussianHaiku('Тихий снегопад\nБелые хлопья кружат\nЗимний сон земли');
    expect(valid.isValid).toBe(true);
    expect(valid.lineSyllables).toEqual([5, 7, 5]);
    
    // Invalid structure
    const invalid = validateRussianHaiku('Слишком много слогов тут\nЭта строка нормальная\nА эта короткая');
    expect(invalid.isValid).toBe(false);
  });
}); 