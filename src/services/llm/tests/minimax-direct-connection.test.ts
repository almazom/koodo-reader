/**
 * Direct Minimax API Connection Test
 * 
 * This test directly connects to the Minimax API without using
 * the provider abstraction, to verify raw connectivity.
 */

import axios from 'axios';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Interfaces for strong typing
interface MessageContent {
  role: 'system' | 'user' | 'assistant';
  content: string;
  name?: string;
}

interface MinimaxRequestPayload {
  model: string;
  messages: MessageContent[];
  temperature?: number;
  max_tokens?: number;
  top_p?: number;
}

interface MinimaxResponseChoice {
  finish_reason: string;
  index: number;
  message: {
    content: string;
    role: string;
    name?: string;
    audio_content?: string;
  };
}

interface MinimaxResponse {
  id: string;
  choices: MinimaxResponseChoice[];
  created: number;
  model: string;
  object: string;
  usage: {
    total_tokens: number;
    total_characters: number;
    prompt_tokens: number;
    completion_tokens: number;
  };
  base_resp: {
    status_code: number;
    status_msg: string;
  };
}

describe('Direct Minimax API Connection', () => {
  // API configuration
  const API_KEY = process.env.MINIMAX_API_KEY || '';
  const BASE_URL = 'https://api.minimaxi.chat/v1/text/chatcompletion_v2';
  const MODEL = 'MiniMax-Text-01';
  
  beforeAll(() => {
    // Check if API key is available
    if (!API_KEY) {
      console.warn('\x1b[33m%s\x1b[0m', 'No API key found in environment variables. Tests will be skipped.');
    }
  });

  // Skip tests if no API key is available
  const conditionalTest = API_KEY ? test : test.skip;

  conditionalTest('should connect to Minimax API and generate a response', async () => {
    // Arrange
    const requestPayload: MinimaxRequestPayload = {
      model: MODEL,
      messages: [
        {
          role: 'system',
          content: 'You are a helpful assistant that provides concise answers.'
        },
        {
          role: 'user',
          content: 'What is the capital of France?'
        }
      ],
      temperature: 0.2,
      max_tokens: 50
    };

    // Display request information for debugging
    console.log('Request URL:', BASE_URL);
    console.log('Request Payload:', JSON.stringify(requestPayload, null, 2));
    
    // Act
    const response = await axios.post<MinimaxResponse>(
      BASE_URL,
      requestPayload,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${API_KEY}`
        }
      }
    );

    // Assert
    expect(response.status).toBe(200);
    expect(response.data).toBeDefined();
    expect(response.data.choices).toBeDefined();
    expect(response.data.choices.length).toBeGreaterThan(0);
    expect(response.data.choices[0].message.content).toBeDefined();
    
    // Display response for debugging
    console.log('Response Status:', response.status);
    console.log('Response Content:', response.data.choices[0].message.content);
    console.log('Token Usage:', response.data.usage);
    
    // Additional assertions for response structure
    expect(response.data.id).toBeDefined();
    expect(response.data.model).toBe(MODEL);
    expect(response.data.usage.total_tokens).toBeGreaterThan(0);
    expect(response.data.base_resp.status_code).toBe(0); // Success code
  });

  conditionalTest('should handle generating Russian text correctly', async () => {
    // Arrange
    const requestPayload: MinimaxRequestPayload = {
      model: MODEL,
      messages: [
        {
          role: 'system',
          content: 'Ты русскоязычный ассистент, который отвечает на вопросы по-русски.'
        },
        {
          role: 'user',
          content: 'Какие три главные достопримечательности Москвы?'
        }
      ],
      temperature: 0.5,
      max_tokens: 100
    };
    
    // Act
    const response = await axios.post<MinimaxResponse>(
      BASE_URL,
      requestPayload,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${API_KEY}`
        }
      }
    );

    // Assert
    expect(response.status).toBe(200);
    expect(response.data.choices[0].message.content).toBeDefined();
    
    // The response should contain Cyrillic characters
    const content = response.data.choices[0].message.content;
    const hasCyrillic = /[а-яА-ЯёЁ]/.test(content);
    expect(hasCyrillic).toBe(true);
    
    // Display response for debugging
    console.log('Russian Response:', content);
    console.log('Russian Token Usage:', response.data.usage);
  });

  conditionalTest('should handle errors gracefully', async () => {
    // Arrange - using an invalid model name on purpose
    const requestPayload: MinimaxRequestPayload = {
      model: 'InvalidModelName',
      messages: [
        {
          role: 'user',
          content: 'Hello'
        }
      ]
    };
    
    try {
      // Act - should throw an error
      await axios.post<MinimaxResponse>(
        BASE_URL,
        requestPayload,
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${API_KEY}`
          }
        }
      );
      
      // If we get here, the test should fail
      expect(true).toBe(false); // This line should not be reached
    } catch (error: any) {
      // Assert
      expect(error).toBeDefined();
      if (error.response) {
        expect(error.response.data).toBeDefined();
        console.log('Error Data:', error.response.data);
      } else {
        console.log('Error:', error.message);
      }
    }
  });
}); 