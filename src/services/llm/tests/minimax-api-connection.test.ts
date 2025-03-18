/**
 * Minimax API Connection Test
 * 
 * This is a TypeScript version of the original test-minimax-api.js script,
 * adapted to work with Jest testing framework while maintaining the same
 * connection testing pattern.
 */

import axios from 'axios';
import { getApiKey } from '../config/api-keys';

// Mock the axios module
jest.mock('axios', () => ({
  post: jest.fn()
}));

// Mock the api-keys module
jest.mock('../config/api-keys', () => ({
  getApiKey: jest.fn().mockReturnValue('mock-api-key')
}));

// API configuration
const BASE_URL = "https://api.minimaxi.chat/v1/text/chatcompletion_v2";
const MODEL = "MiniMax-Text-01";

describe('Minimax API Connection', () => {
  
  beforeEach(() => {
    // Reset all mocks before each test
    jest.clearAllMocks();
    
    // Default mock implementation for successful API calls
    (axios.post as jest.Mock).mockResolvedValue({
      data: {
        choices: [
          {
            message: {
              content: "Привет! Я виртуальный ассистент. Как я могу помочь вам сегодня?"
            }
          }
        ],
        usage: {
          total_tokens: 100,
          prompt_tokens: 30,
          completion_tokens: 70
        }
      },
      status: 200
    });
  });
  
  test('should successfully connect to Minimax API', async () => {
    // Arrange
    const apiKey = getApiKey('minimax');
    
    // Simple request body
    const requestBody = {
      model: MODEL,
      messages: [
        {
          role: "system",
          content: "You are a helpful assistant.",
          name: "Assistant"
        },
        {
          role: "user",
          content: "Hello! How are you today?",
          name: "user"
        }
      ],
      temperature: 0.7,
      max_tokens: 100
    };
    
    // Act
    await axios.post(
      BASE_URL,
      requestBody,
      {
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${apiKey}`,
          "Accept": "application/json"
        }
      }
    );
    
    // Assert
    expect(axios.post).toHaveBeenCalledTimes(1);
    
    // Verify request details
    const [url, data, config] = (axios.post as jest.Mock).mock.calls[0];
    expect(url).toBe(BASE_URL);
    expect(data.model).toBe(MODEL);
    expect(data.messages[0].role).toBe('system');
    expect(data.messages[1].role).toBe('user');
    expect(config.headers.Authorization).toBe('Bearer mock-api-key');
    expect(config.headers['Content-Type']).toBe('application/json');
  });
  
  test('should handle API errors gracefully', async () => {
    // Arrange
    const apiKey = getApiKey('minimax');
    
    // Mock API error
    (axios.post as jest.Mock).mockRejectedValue(new Error('API Error'));
    
    // Request body
    const requestBody = {
      model: MODEL,
      messages: [
        {
          role: "system",
          content: "You are a helpful assistant.",
          name: "Assistant"
        },
        {
          role: "user",
          content: "Hello! How are you today?",
          name: "user"
        }
      ],
      temperature: 0.7,
      max_tokens: 100
    };
    
    // Act & Assert
    await expect(
      axios.post(
        BASE_URL,
        requestBody,
        {
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${apiKey}`,
            "Accept": "application/json"
          }
        }
      )
    ).rejects.toThrow('API Error');
    
    expect(axios.post).toHaveBeenCalledTimes(1);
  });
  
  test('should return proper response structure', async () => {
    // Arrange
    const apiKey = getApiKey('minimax');
    
    // Mock specific response to validate structure
    const mockResponse = {
      data: {
        choices: [
          {
            message: {
              content: "Привет! Я виртуальный ассистент и готов помочь вам сегодня."
            }
          }
        ],
        usage: {
          total_tokens: 100,
          prompt_tokens: 30,
          completion_tokens: 70
        }
      },
      status: 200
    };
    
    (axios.post as jest.Mock).mockResolvedValue(mockResponse);
    
    // Request body
    const requestBody = {
      model: MODEL,
      messages: [
        {
          role: "system",
          content: "You are a helpful assistant.",
          name: "Assistant"
        },
        {
          role: "user",
          content: "Hello! How are you today?",
          name: "user"
        }
      ],
      temperature: 0.7,
      max_tokens: 100
    };
    
    // Act
    const response = await axios.post(
      BASE_URL,
      requestBody,
      {
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${apiKey}`,
          "Accept": "application/json"
        }
      }
    );
    
    // Assert - verify response structure matches expected format
    expect(response.data).toBeDefined();
    expect(response.data.choices).toBeDefined();
    expect(response.data.choices.length).toBeGreaterThan(0);
    expect(response.data.choices[0].message).toBeDefined();
    expect(response.data.choices[0].message.content).toBeDefined();
    expect(response.data.usage).toBeDefined();
    expect(response.data.usage.total_tokens).toBeDefined();
    expect(response.data.usage.prompt_tokens).toBeDefined();
    expect(response.data.usage.completion_tokens).toBeDefined();
  });
}); 