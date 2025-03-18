/**
 * Minimax-hosted DeepSeek-R1 API Test
 * 
 * This test captures and displays the full JSON response
 * from the DeepSeek-R1 model accessed through the Minimax API.
 * 
 * NOTE: Reasoning models like DeepSeek-R1 typically take longer to process
 * requests than standard LLMs due to their enhanced reasoning capabilities.
 */

import axios from 'axios';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Increase Jest timeout for reasoning models which need more processing time
// For reasoning models, we need a much longer timeout than standard LLMs
jest.setTimeout(60000); // 60 seconds timeout

describe('Minimax DeepSeek-R1 API JSON Response', () => {
  // API configuration
  const API_KEY = process.env.MINIMAX_API_KEY || '';
  const BASE_URL = 'https://api.minimaxi.chat/v1/text/chatcompletion_v2';
  const MODEL = 'DeepSeek-R1'; // DeepSeek-R1 model via Minimax
  
  beforeAll(() => {
    // Check if API key is available
    if (!API_KEY) {
      console.warn('\x1b[33m%s\x1b[0m', 'No API key found in environment variables. Tests will be skipped.');
    } else {
      console.log('\x1b[36m%s\x1b[0m', '🧠 Testing DeepSeek-R1 reasoning model - expect longer response times');
    }
  });

  // Skip tests if no API key is available
  const conditionalTest = API_KEY ? test : test.skip;

  conditionalTest('should display full JSON response from DeepSeek-R1 via Minimax API', async () => {
    // Arrange
    const requestPayload = {
      model: MODEL,
      messages: [
        {
          role: 'system',
          content: 'You are a logical AI assistant that excels at step-by-step reasoning. First think through the problem thoroughly in your reasoning_content. Then provide a clear, concise final answer in the content field.'
        },
        {
          role: 'user',
          content: 'If x = 5 and y = 3, what is the value of 2x + 3y? Explain your reasoning step by step.'
        }
      ],
      // For reasoning models, lower temperature often yields more precise answers
      temperature: 0.1,
      // Allow enough tokens for both reasoning AND final answer
      max_tokens: 800,
      // Use top_p for more focused responses on reasoning tasks
      top_p: 0.95
    };

    console.log('\x1b[36m%s\x1b[0m', '📤 Sending request to DeepSeek-R1 reasoning model... (This may take 10-20 seconds)');
    
    // Display request information
    console.log('\n===== REQUEST DETAILS (DeepSeek-R1) =====');
    console.log('URL:', BASE_URL);
    console.log('Model:', MODEL);
    console.log('Request Payload:', JSON.stringify(requestPayload, null, 2));
    
    // For measuring response time
    const startTime = Date.now();
    
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
          // Add timeout for the HTTP request itself
          timeout: 50000 // 50 seconds HTTP timeout
        }
      );

      // Calculate and display response time
      const responseTime = (Date.now() - startTime) / 1000;
      console.log(`\n✅ Response received in ${responseTime.toFixed(2)} seconds`);

      // Display full JSON response
      console.log('\n===== FULL JSON RESPONSE (DeepSeek-R1) =====');
      console.log(JSON.stringify(response.data, null, 2));
      
      // Display token usage information
      console.log('\n===== TOKEN USAGE (DeepSeek-R1) =====');
      console.log(`Total Tokens: ${response.data.usage.total_tokens}`);
      console.log(`Prompt Tokens: ${response.data.usage.prompt_tokens}`);
      console.log(`Completion Tokens: ${response.data.usage.completion_tokens}`);

      // Display answer information
      console.log('\n===== ANSWER CONTENT (DeepSeek-R1) =====');
      console.log('Answer:', response.data.choices[0].message.content);
      console.log('Finish Reason:', response.data.choices[0].finish_reason);
      
      // Check if we have the reasoning_content field - unique to DeepSeek R1
      if (response.data.choices[0].message.reasoning_content) {
        console.log('\n===== REASONING CONTENT (DeepSeek-R1 specific) =====');
        console.log(response.data.choices[0].message.reasoning_content);
      }
      
      // Assert
      expect(response.status).toBe(200);
      expect(response.data.choices.length).toBeGreaterThan(0);
      expect(response.data.choices[0].message.content).toBeDefined();
      expect(response.data.usage).toBeDefined();
    } catch (error) {
      // For timeout errors, provide clearer messaging
      if (error.code === 'ECONNABORTED') {
        console.error('\x1b[31m%s\x1b[0m', '⏱️ Request timed out! Reasoning models may need more time.');
        console.error('Consider increasing the timeout or simplifying the prompt.');
      } else {
        console.error('\x1b[31m%s\x1b[0m', '❌ Error during API request:');
        console.error('Error details:', error.response?.data || error.message);
      }
      // Still fail the test
      fail('API request failed: ' + (error.response?.data?.error?.message || error.message));
    }
  });

  conditionalTest('should test DeepSeek-R1 reasoning capabilities', async () => {
    // Arrange
    const requestPayload = {
      model: MODEL,
      messages: [
        {
          role: 'system',
          // For reasoning models, be very explicit about reasoning steps and final answer
          content: 'You are a logical reasoning engine that solves problems step by step. Always number your steps and explain each operation clearly. Perform your detailed reasoning process in reasoning_content, then provide a clear, concise final answer in content.'
        },
        {
          role: 'user',
          content: 'John has 5 apples. Mary gives him twice as many apples as he already has. Then he gives 3 apples to his friend. How many apples does John have now? Walk through the solution step by step.'
        }
      ],
      temperature: 0.1,
      max_tokens: 1000, // Increased to ensure we get both reasoning and content
      top_p: 0.9
    };

    console.log('\x1b[36m%s\x1b[0m', '📤 Testing reasoning capabilities... (This may take 10-20 seconds)');
    
    // Display request information
    console.log('\n===== REASONING REQUEST DETAILS (DeepSeek-R1) =====');
    console.log('URL:', BASE_URL);
    console.log('Model:', MODEL);
    console.log('Request Payload:', JSON.stringify(requestPayload, null, 2));
    
    const startTime = Date.now();
    
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
          timeout: 50000
        }
      );

      // Calculate and display response time
      const responseTime = (Date.now() - startTime) / 1000;
      console.log(`\n✅ Response received in ${responseTime.toFixed(2)} seconds`);

      // Display full JSON response
      console.log('\n===== FULL REASONING JSON RESPONSE (DeepSeek-R1) =====');
      console.log(JSON.stringify(response.data, null, 2));
      
      // Display token usage information
      console.log('\n===== REASONING TOKEN USAGE (DeepSeek-R1) =====');
      console.log(`Total Tokens: ${response.data.usage.total_tokens}`);
      console.log(`Prompt Tokens: ${response.data.usage.prompt_tokens}`);
      console.log(`Completion Tokens: ${response.data.usage.completion_tokens}`);

      // Display answer information
      console.log('\n===== REASONING ANSWER CONTENT (DeepSeek-R1) =====');
      console.log('Answer:', response.data.choices[0].message.content);
      console.log('Finish Reason:', response.data.choices[0].finish_reason);
      
      // Assert
      expect(response.status).toBe(200);
      expect(response.data.choices.length).toBeGreaterThan(0);
      expect(response.data.choices[0].message.content).toBeDefined();
      expect(response.data.usage).toBeDefined();
      
      // Check if the response contains elements of step-by-step reasoning
      // We'll check for numbers, steps, or sequential indicators
      const content = response.data.choices[0].message.content.toLowerCase();
      const containsStepByStep = 
        content.includes('step') || 
        content.includes('1.') || 
        content.includes('2.') || 
        content.includes('first') || 
        content.includes('second') ||
        content.includes('initially') ||
        (content.includes('then') && content.includes('finally'));
      
      expect(containsStepByStep).toBe(true);
      
      // Check for reasoning_content - a special feature of DeepSeek models
      if (response.data.choices[0].message.reasoning_content) {
        console.log('\n===== REASONING CONTENT ANALYSIS =====');
        console.log('Reasoning content length:', response.data.choices[0].message.reasoning_content.length);
        console.log('Reasoning Content:', response.data.choices[0].message.reasoning_content);
      }
    } catch (error) {
      if (error.code === 'ECONNABORTED') {
        console.error('\x1b[31m%s\x1b[0m', '⏱️ Request timed out! Reasoning models often take longer for complex tasks.');
      } else {
        console.error('\x1b[31m%s\x1b[0m', '❌ Error during reasoning test:');
        console.error('Error details:', error.response?.data || error.message);
      }
      fail('API request failed: ' + (error.response?.data?.error?.message || error.message));
    }
  });

  conditionalTest('should test DeepSeek-R1 with Russian language', async () => {
    // Arrange
    const requestPayload = {
      model: MODEL,
      messages: [
        {
          role: 'system',
          content: 'Ты помощник, который отвечает на вопросы логически, шаг за шагом. Всегда пронумеруй шаги рассуждения и объясняй каждое действие ясно. Показывай свои рассуждения в reasoning_content, а окончательный ответ в content.'
        },
        {
          role: 'user',
          content: 'У Ивана было 8 книг. Он подарил половину своих книг Марии, а потом купил еще 3 книги. Сколько книг у него теперь? Объясни ответ по шагам.'
        }
      ],
      temperature: 0.1,
      max_tokens: 800 // Increased for both reasoning and content
    };

    console.log('\x1b[36m%s\x1b[0m', '📤 Testing Russian language capabilities... (This may take 10-20 seconds)');
    
    // Display request information
    console.log('\n===== RUSSIAN REQUEST DETAILS (DeepSeek-R1) =====');
    console.log('URL:', BASE_URL);
    console.log('Model:', MODEL);
    console.log('Request Payload:', JSON.stringify(requestPayload, null, 2));
    
    const startTime = Date.now();
    
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
          timeout: 50000
        }
      );

      // Calculate and display response time
      const responseTime = (Date.now() - startTime) / 1000;
      console.log(`\n✅ Response received in ${responseTime.toFixed(2)} seconds`);

      // Display full JSON response
      console.log('\n===== FULL RUSSIAN JSON RESPONSE (DeepSeek-R1) =====');
      console.log(JSON.stringify(response.data, null, 2));
      
      // Display token usage information
      console.log('\n===== RUSSIAN TOKEN USAGE (DeepSeek-R1) =====');
      console.log(`Total Tokens: ${response.data.usage.total_tokens}`);
      console.log(`Prompt Tokens: ${response.data.usage.prompt_tokens}`);
      console.log(`Completion Tokens: ${response.data.usage.completion_tokens}`);

      // Display answer information
      console.log('\n===== RUSSIAN ANSWER CONTENT (DeepSeek-R1) =====');
      console.log('Answer:', response.data.choices[0].message.content);
      console.log('Finish Reason:', response.data.choices[0].finish_reason);
      
      // Check if we have the reasoning_content field
      if (response.data.choices[0].message.reasoning_content) {
        console.log('\n===== RUSSIAN REASONING CONTENT (DeepSeek-R1 specific) =====');
        console.log(response.data.choices[0].message.reasoning_content);
      }
      
      // Assert
      expect(response.status).toBe(200);
      expect(response.data.choices.length).toBeGreaterThan(0);
      expect(response.data.choices[0].message.content).toBeDefined();
      expect(response.data.usage).toBeDefined();
      
      // Check if the response contains Cyrillic characters
      const content = response.data.choices[0].message.content;
      expect(/[а-яА-ЯёЁ]/.test(content)).toBe(true);
    } catch (error) {
      if (error.code === 'ECONNABORTED') {
        console.error('\x1b[31m%s\x1b[0m', '⏱️ Request timed out! Russian language reasoning may require more processing time.');
      } else {
        console.error('\x1b[31m%s\x1b[0m', '❌ Error during Russian language test:');
        console.error('Error details:', error.response?.data || error.message);
      }
      fail('API request failed: ' + (error.response?.data?.error?.message || error.message));
    }
  });

  conditionalTest('should display response metadata from DeepSeek-R1', async () => {
    // Use a simpler prompt for metadata testing to reduce response time
    const requestPayload = {
      model: MODEL,
      messages: [
        {
          role: 'system',
          content: 'You are a helpful assistant.'
        },
        {
          role: 'user',
          content: 'Briefly describe the DeepSeek-R1 model in one sentence.'
        }
      ],
      temperature: 0.7,
      max_tokens: 100
    };

    console.log('\x1b[36m%s\x1b[0m', '📤 Testing metadata response... (This should be quicker)');
    
    const startTime = Date.now();
    
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
          timeout: 30000 // Shorter timeout for simpler query
        }
      );
      
      // Calculate and display response time
      const responseTime = (Date.now() - startTime) / 1000;
      console.log(`\n✅ Response received in ${responseTime.toFixed(2)} seconds`);
      
      // Display metadata from response
      console.log('\n===== RESPONSE METADATA (DeepSeek-R1) =====');
      console.log('Response ID:', response.data.id);
      console.log('Created Timestamp:', response.data.created);
      console.log('Model Used:', response.data.model);
      console.log('Object Type:', response.data.object);
      console.log('Base Status Code:', response.data.base_resp.status_code);
      console.log('Base Status Message:', response.data.base_resp.status_msg);
      console.log('Input Sensitive:', response.data.input_sensitive);
      console.log('Output Sensitive:', response.data.output_sensitive);
      
      // Check for any additional fields specific to DeepSeek
      const uniqueFields = Object.keys(response.data).filter(key => 
        !['id', 'choices', 'created', 'model', 'object', 'usage', 'base_resp'].includes(key)
      );
      
      if (uniqueFields.length > 0) {
        console.log('\n===== UNIQUE DeepSeek-R1 RESPONSE FIELDS =====');
        uniqueFields.forEach(field => {
          console.log(`${field}:`, response.data[field]);
        });
      }
      
      // Check if we have the additional reasoning_content field - that's unique to DeepSeek
      if (response.data.choices[0].message.reasoning_content) {
        console.log('\n===== REASONING CONTENT (DeepSeek-R1 specific) =====');
        console.log(response.data.choices[0].message.reasoning_content);
      }
      
      // Assert
      expect(response.status).toBe(200);
      expect(response.data.model).toBe(MODEL);
      expect(response.data.id).toBeDefined();
      expect(response.data.created).toBeDefined();
      expect(response.data.base_resp.status_code).toBe(0); // Success code
    } catch (error) {
      if (error.code === 'ECONNABORTED') {
        console.error('\x1b[31m%s\x1b[0m', '⏱️ Request timed out! Even simple queries may occasionally time out.');
      } else {
        console.error('\x1b[31m%s\x1b[0m', '❌ Error during metadata test:');
        console.error('Error details:', error.response?.data || error.message);
      }
      fail('API request failed: ' + (error.response?.data?.error?.message || error.message));
    }
  });

  // Add a specific test to check both reasoning_content and content fields
  conditionalTest('should verify both reasoning_content and content fields are populated', async () => {
    // Arrange
    const requestPayload = {
      model: MODEL,
      messages: [
        {
          role: 'system',
          content: 'You are a helpful assistant with advanced reasoning capabilities. First, think through the problem step by step in your reasoning_content. Then provide a clear, concise final answer in the content field.'
        },
        {
          role: 'user',
          content: 'A train travels at 60 km/h for 2 hours, then at 80 km/h for 1 hour. What is the average speed of the train for the entire journey?'
        }
      ],
      temperature: 0.1,
      max_tokens: 1000 // Plenty of tokens for both reasoning and final answer
    };

    console.log('\x1b[36m%s\x1b[0m', '📤 Testing content and reasoning_content separation... (This may take 10-20 seconds)');
    
    const startTime = Date.now();
    
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
          timeout: 50000
        }
      );

      // Calculate and display response time
      const responseTime = (Date.now() - startTime) / 1000;
      console.log(`\n✅ Response received in ${responseTime.toFixed(2)} seconds`);

      // Display both reasoning_content and content
      console.log('\n===== FULL JSON RESPONSE (DeepSeek-R1) =====');
      console.log(JSON.stringify(response.data, null, 2));
      
      console.log('\n===== REASONING CONTENT =====');
      console.log(response.data.choices[0].message.reasoning_content || 'No reasoning content');
      
      console.log('\n===== FINAL ANSWER CONTENT =====');
      console.log(response.data.choices[0].message.content || 'No content');
      
      // Display token usage information
      console.log('\n===== TOKEN USAGE (DeepSeek-R1) =====');
      console.log(`Total Tokens: ${response.data.usage.total_tokens}`);
      console.log(`Prompt Tokens: ${response.data.usage.prompt_tokens}`);
      console.log(`Completion Tokens: ${response.data.usage.completion_tokens}`);

      // Assert
      expect(response.status).toBe(200);
      expect(response.data.choices.length).toBeGreaterThan(0);
      expect(response.data.choices[0].message.reasoning_content).toBeDefined();
      expect(response.data.choices[0].message.reasoning_content.length).toBeGreaterThan(0);
      expect(response.data.choices[0].message.content).toBeDefined();
      expect(response.data.choices[0].message.content.length).toBeGreaterThan(0);
    } catch (error) {
      if (error.code === 'ECONNABORTED') {
        console.error('\x1b[31m%s\x1b[0m', '⏱️ Request timed out! Reasoning models may need more time.');
      } else {
        console.error('\x1b[31m%s\x1b[0m', '❌ Error during content/reasoning test:');
        console.error('Error details:', error.response?.data || error.message);
      }
      fail('API request failed: ' + (error.response?.data?.error?.message || error.message));
    }
  });
}); 