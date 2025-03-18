/**
 * Minimax API JSON Response Test
 * 
 * This test explicitly captures and displays the full JSON response
 * from the Minimax API to better understand the response structure.
 */

import axios from 'axios';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

describe('Minimax API JSON Response', () => {
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

  conditionalTest('should display full JSON response from Minimax API', async () => {
    // Arrange
    const requestPayload = {
      model: MODEL,
      messages: [
        {
          role: 'system',
          content: 'You are a helpful assistant that provides concise answers.'
        },
        {
          role: 'user',
          content: 'What is the capital of France? Answer in one word.'
        }
      ],
      temperature: 0.2,
      max_tokens: 20
    };

    // Display request information
    console.log('\n===== REQUEST DETAILS =====');
    console.log('URL:', BASE_URL);
    console.log('Model:', MODEL);
    console.log('Request Payload:', JSON.stringify(requestPayload, null, 2));
    
    // Act
    const response = await axios.post(
      BASE_URL,
      requestPayload,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${API_KEY}`
        }
      }
    );

    // Display full JSON response
    console.log('\n===== FULL JSON RESPONSE =====');
    // Using util.inspect would be better for objects, but for simplicity we'll use JSON.stringify
    console.log(JSON.stringify(response.data, null, 2));
    
    // Display token usage information
    console.log('\n===== TOKEN USAGE =====');
    console.log(`Total Tokens: ${response.data.usage.total_tokens}`);
    console.log(`Prompt Tokens: ${response.data.usage.prompt_tokens}`);
    console.log(`Completion Tokens: ${response.data.usage.completion_tokens}`);

    // Display answer information
    console.log('\n===== ANSWER CONTENT =====');
    console.log('Answer:', response.data.choices[0].message.content);
    console.log('Finish Reason:', response.data.choices[0].finish_reason);
    
    // Assert
    expect(response.status).toBe(200);
    expect(response.data.choices.length).toBeGreaterThan(0);
    expect(response.data.choices[0].message.content).toBeDefined();
    expect(response.data.usage).toBeDefined();
  });

  conditionalTest('should display full JSON response for Russian query', async () => {
    // Arrange
    const requestPayload = {
      model: MODEL,
      messages: [
        {
          role: 'system',
          content: 'Ты русскоязычный ассистент, отвечающий на вопросы кратко.'
        },
        {
          role: 'user',
          content: 'Какая столица России? Ответь одним словом.'
        }
      ],
      temperature: 0.2,
      max_tokens: 20
    };

    // Display request information
    console.log('\n===== RUSSIAN REQUEST DETAILS =====');
    console.log('URL:', BASE_URL);
    console.log('Model:', MODEL);
    console.log('Request Payload:', JSON.stringify(requestPayload, null, 2));
    
    // Act
    const response = await axios.post(
      BASE_URL,
      requestPayload,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${API_KEY}`
        }
      }
    );

    // Display full JSON response
    console.log('\n===== FULL RUSSIAN JSON RESPONSE =====');
    console.log(JSON.stringify(response.data, null, 2));
    
    // Display token usage information
    console.log('\n===== RUSSIAN TOKEN USAGE =====');
    console.log(`Total Tokens: ${response.data.usage.total_tokens}`);
    console.log(`Prompt Tokens: ${response.data.usage.prompt_tokens}`);
    console.log(`Completion Tokens: ${response.data.usage.completion_tokens}`);

    // Display answer information
    console.log('\n===== RUSSIAN ANSWER CONTENT =====');
    console.log('Answer:', response.data.choices[0].message.content);
    console.log('Finish Reason:', response.data.choices[0].finish_reason);
    
    // Assert
    expect(response.status).toBe(200);
    expect(response.data.choices.length).toBeGreaterThan(0);
    expect(response.data.choices[0].message.content).toBeDefined();
    expect(response.data.usage).toBeDefined();
    expect(/[а-яА-ЯёЁ]/.test(response.data.choices[0].message.content)).toBe(true);
  });

  conditionalTest('should display JSON response with system parameters', async () => {
    // Arrange
    const requestPayload = {
      model: MODEL,
      messages: [
        {
          role: 'system',
          content: 'You are an AI assistant specialized in JSON formatting. Always provide your answer in valid JSON format.'
        },
        {
          role: 'user',
          content: 'Generate a sample book object with title, author, and genre fields.'
        }
      ],
      temperature: 0.2,
      max_tokens: 150
    };

    // Display request information
    console.log('\n===== JSON REQUEST DETAILS =====');
    console.log('URL:', BASE_URL);
    console.log('Model:', MODEL);
    console.log('Request Payload:', JSON.stringify(requestPayload, null, 2));
    
    // Act
    const response = await axios.post(
      BASE_URL,
      requestPayload,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${API_KEY}`
        }
      }
    );

    // Display full JSON response
    console.log('\n===== FULL JSON RESPONSE WITH SYSTEM PARAMETERS =====');
    console.log(JSON.stringify(response.data, null, 2));
    
    // Display metadata from response
    console.log('\n===== RESPONSE METADATA =====');
    console.log('Response ID:', response.data.id);
    console.log('Created Timestamp:', response.data.created);
    console.log('Model Used:', response.data.model);
    console.log('Object Type:', response.data.object);
    console.log('Base Status Code:', response.data.base_resp.status_code);
    console.log('Base Status Message:', response.data.base_resp.status_msg);
    
    // Assert
    expect(response.status).toBe(200);
    expect(response.data.choices.length).toBeGreaterThan(0);
    expect(response.data.choices[0].message.content).toBeDefined();
    
    // Try to parse the response as JSON to verify it's valid JSON
    let isValidJson = false;
    try {
      const jsonContent = JSON.parse(response.data.choices[0].message.content);
      isValidJson = true;
      console.log('\n===== PARSED JSON CONTENT =====');
      console.log(jsonContent);
    } catch (error) {
      console.warn('The response is not valid JSON:', error);
    }
    
    expect(isValidJson).toBe(true);
  });
}); 