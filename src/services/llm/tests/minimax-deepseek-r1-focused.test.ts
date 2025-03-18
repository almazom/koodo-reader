/**
 * Focused DeepSeek-R1 Test for Content and Reasoning Content
 * 
 * This test specifically verifies the proper working of both content and reasoning_content fields
 * in the DeepSeek-R1 model via Minimax API.
 */

import axios from 'axios';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Increase Jest timeout for reasoning models
jest.setTimeout(60000);

describe('DeepSeek-R1 Content and Reasoning Test', () => {
  // API configuration
  const API_KEY = process.env.MINIMAX_API_KEY || '';
  const BASE_URL = 'https://api.minimaxi.chat/v1/text/chatcompletion_v2';
  const MODEL = 'DeepSeek-R1';
  
  beforeAll(() => {
    if (!API_KEY) {
      console.warn('\x1b[33m%s\x1b[0m', 'No API key found in environment variables. Tests will be skipped.');
    } else {
      console.log('\x1b[36m%s\x1b[0m', '🧠 Starting focused DeepSeek-R1 content/reasoning test');
    }
  });

  // Skip tests if no API key is available
  const conditionalTest = API_KEY ? test : test.skip;

  conditionalTest('should properly populate both content and reasoning_content fields', async () => {
    // Arrange - Use a simple math problem that requires reasoning
    const requestPayload = {
      model: MODEL,
      messages: [
        {
          role: 'system',
          content: 'You are a helpful assistant. When asked a question, first think through your reasoning in reasoning_content, then provide a concise final answer in content.'
        },
        {
          role: 'user',
          content: 'What is 25 × 13?'
        }
      ],
      temperature: 0.1,
      max_tokens: 800 // Plenty of tokens for both reasoning and content
    };

    console.log('\x1b[36m%s\x1b[0m', '📤 Testing content and reasoning_content fields...');
    
    try {
      // Act
      const response = await axios.post(
        BASE_URL,
        requestPayload,
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${API_KEY}`
          },
          timeout: 30000
        }
      );

      // Output the full response for inspection
      console.log('\n===== FULL JSON RESPONSE =====');
      console.log(JSON.stringify(response.data, null, 2));
      
      // Display the specific fields we're interested in
      console.log('\n===== REASONING CONTENT =====');
      console.log(response.data.choices[0].message.reasoning_content || 'No reasoning content');
      
      console.log('\n===== FINAL ANSWER CONTENT =====');
      console.log(response.data.choices[0].message.content || 'No content');
      
      // Display token usage for reference
      console.log('\n===== TOKEN USAGE =====');
      console.log(`Total Tokens: ${response.data.usage.total_tokens}`);
      console.log(`Prompt Tokens: ${response.data.usage.prompt_tokens}`);
      console.log(`Completion Tokens: ${response.data.usage.completion_tokens}`);

      // Assert that both fields are populated
      expect(response.data.choices[0].message.reasoning_content).toBeTruthy();
      expect(response.data.choices[0].message.content).toBeTruthy();
      
      // These assertions might be more specific depending on what we expect
      expect(response.data.choices[0].message.reasoning_content.length).toBeGreaterThan(20);
      expect(response.data.choices[0].message.content.length).toBeGreaterThan(2);
    } catch (error) {
      console.error('\x1b[31m%s\x1b[0m', '❌ Error during test:');
      console.error('Error details:', error.response?.data || error.message);
      fail('API request failed: ' + (error.response?.data?.error?.message || error.message));
    }
  });
}); 