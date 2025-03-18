#!/usr/bin/env node
/**
 * Simple Minimax API Test - Russian Haiku Generator
 * 
 * This is a minimal, direct test of the Minimax API connection
 * that generates a Russian haiku about a given theme.
 */

const axios = require('axios');
require('dotenv').config();

// Colors for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m'
};

// Minimax API config
const API_KEY = process.env.MINIMAX_API_KEY || "your-api-key-here"; // Replace with your actual key
const BASE_URL = "https://api.minimaxi.chat/v1/text/chatcompletion_v2";
const MODEL = "MiniMax-Text-01";

// Russian vowels for syllable counting (optional feature)
const russianVowels = ['а', 'е', 'ё', 'и', 'о', 'у', 'ы', 'э', 'ю', 'я'];

/**
 * Count syllables in a Russian word
 */
function countSyllablesInWord(word) {
  const lowerWord = word.toLowerCase();
  let count = 0;
  
  for (let i = 0; i < lowerWord.length; i++) {
    if (russianVowels.includes(lowerWord[i])) {
      count++;
    }
  }
  
  return count;
}

/**
 * Count syllables in a line of Russian text
 */
function countSyllablesInLine(line) {
  const words = line.trim().split(/\s+/);
  return words.reduce((total, word) => total + countSyllablesInWord(word), 0);
}

/**
 * Show syllable information for a haiku (informational only)
 */
function analyzeHaikuSyllables(haiku) {
  const lines = haiku.trim().split('\n');
  const lineSyllables = lines.map(line => countSyllablesInLine(line));
  
  return {
    lines: lines.length,
    syllables: lineSyllables,
    pattern: lineSyllables.join('-')
  };
}

/**
 * Generate a Russian haiku about a theme using Minimax API
 */
async function generateRussianHaiku(theme) {
  console.log(`${colors.cyan}Generating Russian haiku about "${theme}"...${colors.reset}`);
  
  try {
    // Simple request body with Russian prompts
    const requestBody = {
      model: MODEL,
      messages: [
        {
          role: "system", 
          content: "Ты профессиональный поэт, специализирующийся на создании хайку на русском языке. Хайку - это традиционная японская форма поэзии, состоящая из трех строк. В русской адаптации хайку обычно следует схеме 5-7-5 слогов."
        },
        {
          role: "user",
          content: `Напиши хайку на русском языке на тему "${theme}". Хайку должно вызывать яркие образы и эмоции, связанные с природой и временем года.`
        }
      ],
      temperature: 0.8,
      max_tokens: 100
    };
    
    // Print request details for debugging
    console.log(`${colors.blue}Request details:${colors.reset}`);
    console.log(`${colors.cyan}URL:${colors.reset} ${BASE_URL}`);
    console.log(`${colors.cyan}Model:${colors.reset} ${MODEL}`);
    console.log(`${colors.cyan}API Key (first 10 chars):${colors.reset} ${API_KEY.substring(0, 10)}...`);
    console.log(`${colors.cyan}Request body:${colors.reset}`, JSON.stringify(requestBody, null, 2));
    
    console.log(`${colors.blue}Отправка запроса к API Minimax...${colors.reset}`);
    
    // Make API call
    const response = await axios.post(
      BASE_URL,
      requestBody,
      {
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${API_KEY}`
        }
      }
    );
    
    // Debug: Log the entire response
    console.log(`${colors.yellow}Full API Response:${colors.reset}`);
    console.log(JSON.stringify(response.data, null, 2));
    console.log(`${colors.yellow}Response Status:${colors.reset} ${response.status}`);
    console.log(`${colors.yellow}Response Headers:${colors.reset}`, response.headers);
    
    // Process response
    if (response.status === 200) {
      let haiku;
      let usage = { total_tokens: 0, prompt_tokens: 0, completion_tokens: 0 };
      
      // Handle different response formats
      if (response.data.choices && response.data.choices.length > 0) {
        console.log(`${colors.cyan}Choices found in response:${colors.reset}`, response.data.choices);
        
        if (response.data.choices[0].message && response.data.choices[0].message.content) {
          haiku = response.data.choices[0].message.content;
        } else if (response.data.choices[0].text) {
          haiku = response.data.choices[0].text;
        } else if (response.data.choices[0].content) {
          haiku = response.data.choices[0].content;
        } else {
          console.log(`${colors.yellow}Unexpected choice structure:${colors.reset}`, response.data.choices[0]);
          haiku = JSON.stringify(response.data.choices[0]);
        }
      } else if (response.data.response) {
        haiku = response.data.response;
      } else {
        console.log(`${colors.yellow}No recognizable content in response:${colors.reset}`, response.data);
        haiku = "API connected but returned unexpected format";
      }
      
      // Extract usage information if available
      if (response.data.usage) {
        usage = response.data.usage;
      }
      
      // Analyze syllable structure (optional feature)
      const analysis = analyzeHaikuSyllables(haiku);
      
      // Display results
      console.log(`\n${colors.green}✓ Соединение с API успешно!${colors.reset}`);
      console.log(`\n${colors.magenta}Сгенерированное хайку:${colors.reset}`);
      console.log(`${colors.yellow}${haiku}${colors.reset}`);
      
      console.log(`\n${colors.blue}Информация о слогах:${colors.reset}`);
      console.log(`${colors.cyan}Строки: ${analysis.lines}, Структура: ${analysis.pattern}${colors.reset}`);
      
      if (usage.total_tokens > 0) {
        console.log(`\n${colors.blue}Использование токенов:${colors.reset}`);
        console.log(`${colors.cyan}Всего: ${usage.total_tokens}${colors.reset}`);
        console.log(`${colors.cyan}Промпт: ${usage.prompt_tokens}${colors.reset}`);
        console.log(`${colors.cyan}Ответ: ${usage.completion_tokens}${colors.reset}`);
      } else {
        console.log(`\n${colors.blue}Информация об использовании токенов отсутствует${colors.reset}`);
      }
      
      return {
        success: true,
        haiku,
        analysis,
        usage
      };
    } else {
      throw new Error(`Неверный статус ответа: ${response.status}`);
    }
  } catch (error) {
    console.error(`${colors.red}Ошибка соединения с API Minimax:${colors.reset}`, error.message);
    
    // Enhanced error logging
    if (error.response) {
      console.error(`${colors.red}Статус ошибки:${colors.reset}`, error.response.status);
      console.error(`${colors.red}Заголовки ответа:${colors.reset}`, error.response.headers);
      console.error(`${colors.red}Данные ответа:${colors.reset}`, JSON.stringify(error.response.data, null, 2));
    } else if (error.request) {
      console.error(`${colors.red}Запрос был сделан, но ответ не получен:${colors.reset}`, error.request);
    } else {
      console.error(`${colors.red}Ошибка при настройке запроса:${colors.reset}`, error.message);
    }
    console.error(`${colors.red}Полная ошибка:${colors.reset}`, error);
    
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Main function
 */
async function main() {
  console.log(`${colors.magenta}=== ТЕСТ СОЕДИНЕНИЯ С API MINIMAX ===${colors.reset}\n`);
  
  // Test themes in Russian
  const themes = ["весна", "море", "горы", "закат", "зима", "дождь"];
  
  // Generate a haiku for the first theme
  const result = await generateRussianHaiku(themes[0]);
  
  if (result.success) {
    console.log(`\n${colors.green}Тест успешно завершен!${colors.reset}`);
  } else {
    console.log(`\n${colors.red}Тест не удался.${colors.reset}`);
    process.exit(1);
  }
}

// Run the main function
main().catch(console.error); 