/**
 * Russian Haiku Generator using MiniMax API
 */

const axios = require('axios');

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  italic: '\x1b[3m',
  underscore: '\x1b[4m',
  
  fg: {
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
    white: '\x1b[37m',
  },
  bg: {
    blue: '\x1b[44m',
  }
};

// Russian vowels for syllable counting
const russianVowels = ['а', 'е', 'ё', 'и', 'о', 'у', 'ы', 'э', 'ю', 'я'];

// MiniMax API configuration
const minimaxConfig = {
  apiKey: process.env.MINIMAX_API || "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJHcm91cE5hbWUiOiJBbG1heiBCaWtjaHVyaW4iLCJVc2VyTmFtZSI6IkFsbWF6IEJpa2NodXJpbiIsIkFjY291bnQiOiIiLCJTdWJqZWN0SUQiOiIxODc5ODU0Njg2MTQ0NTY1NTMxIiwiUGhvbmUiOiIiLCJHcm91cElEIjoiMTg3OTg1NDY4NjEzNjE3NjkyMyIsIlBhZ2VOYW1lIjoiIiwiTWFpbCI6ImFsbWF6b21hbUBnbWFpbC5jb20iLCJDcmVhdGVUaW1lIjoiMjAyNS0wMy0xNCAxOToyODo1MSIsIlRva2VuVHlwZSI6MSwiaXNzIjoibWluaW1heCJ9.CtEgIVQqKs-rZDLufflehcnm6bC-p7ppH072Ymo6-p9kOSV5_LR0Ayog0ogH-ZRYu_lZ6z5ycx2TIEek5se-b41Fq4hkrPwREVIM9lvQ8d0RLC2vYNoldF6ZLhBFwwszW3JHK5YqPmN7U_ljKWtlaPGQKSUlmRUXVI4AYUGZ85by8GmXRBJKohihu7whKi71OILZSBsDKBajC00wsF_uRSirT7rSwc_AQvA48tYI7bqgOP17j6GfWZe_VlggqqJYeiTznSaCdi42FG8SO8bTSMnXeE7UstwXL4XO9scVNNBy0iWYPeAzJfvlMbKeIVK71zzXgb9AMhE3zolJWv7jxQ",
  baseUrl: 'https://api.minimaxi.chat/v1/text/chatcompletion_v2',
  model: 'MiniMax-Text-01'
};

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
 * Generate a Russian haiku about a theme using MiniMax API
 */
async function generateRussianHaiku(theme) {
  const systemMessage = 'Ты профессиональный поэт, специализирующийся на создании хайку на русском языке. ' +
    'Хайку - это традиционная японская форма поэзии, состоящая из трех строк. ' +
    'Твоя задача - создать красивое, элегантное хайку на русском языке по заданной теме.';
  
  const userMessage = `Напиши хайку на русском языке на тему "${theme}". ` +
    'Хайку должно вызывать яркие образы и эмоции, связанные с природой и временем года.';

  console.log(`${colors.fg.yellow}${colors.bright}Генерация хайку на тему "${theme}"...${colors.reset}`);
  console.log(`${colors.dim}(Generating haiku on the theme of "${theme}")${colors.reset}`);
  
  try {
    const requestBody = {
      model: minimaxConfig.model,
      messages: [
        { 
          role: 'system', 
          content: systemMessage,
          name: "Russian Haiku Generator"
        },
        { 
          role: 'user', 
          content: userMessage,
          name: "user"
        }
      ],
      temperature: 0.8,
      max_tokens: 300
    };
    
    console.log(`${colors.dim}Sending request to ${minimaxConfig.baseUrl}${colors.reset}`);
    
    const response = await axios.post(
      minimaxConfig.baseUrl,
      requestBody,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${minimaxConfig.apiKey}`,
          'Accept': 'application/json'
        }
      }
    );
    
    // Extract data from response - check if it exists
    if (!response.data.choices || !response.data.choices.length) {
      throw new Error(`Invalid API response: No choices returned.`);
    }
    
    const haiku = response.data.choices[0].message.content;
    const tokensUsed = response.data.usage.total_tokens;
    const tokensInput = response.data.usage.prompt_tokens;
    const tokensOutput = response.data.usage.completion_tokens;
    
    // Analyze the haiku (just for information)
    const analysis = analyzeHaikuSyllables(haiku);
    
    // Display the haiku
    console.log(`\n${colors.fg.cyan}${colors.bright}▶ Хайку:${colors.reset}`);
    console.log(`${colors.fg.white}${colors.italic}${haiku}${colors.reset}`);
    
    // Display syllable information (just for reference)
    console.log(`\n${colors.fg.blue}Строки: ${analysis.lines}, Слоги: ${analysis.pattern}${colors.reset}`);
    
    // Display token usage
    console.log(`${colors.fg.magenta}Использовано токенов: ${tokensUsed} (вход: ${tokensInput}, выход: ${tokensOutput})${colors.reset}`);
    console.log(`${colors.fg.blue}Модель: ${minimaxConfig.model}${colors.reset}`);
    
    return { haiku, tokensUsed, tokensInput, tokensOutput };
  } catch (error) {
    console.error(`${colors.fg.red}Ошибка при генерации хайку: ${error.message}${colors.reset}`);
    if (error.response) {
      console.error(`${colors.fg.red}Статус ошибки: ${error.response.status}${colors.reset}`);
      console.error(`${colors.fg.red}Детали ошибки: ${JSON.stringify(error.response.data, null, 2)}${colors.reset}`);
    }
    throw error;
  }
}

/**
 * Main function to run the demo
 */
async function runDemo() {
  console.log(`${colors.bright}${colors.bg.blue}${colors.fg.white} Русский Хайку Генератор | Russian Haiku Generator ${colors.reset}\n`);
  
  // Themes to generate haikus for
  const themes = [
    'зима', // winter
    'весна', // spring
    'лето', // summer
    'осень', // autumn
    'море', // sea
    'горы', // mountains
    'книги', // books
  ];
  
  for (const theme of themes) {
    try {
      await generateRussianHaiku(theme);
      console.log(`\n${colors.dim}${'─'.repeat(50)}${colors.reset}\n`);
    } catch (error) {
      console.error(`${colors.fg.red}Невозможно сгенерировать хайку для темы "${theme}": ${error.message}${colors.reset}`);
      console.log(`\n${colors.dim}${'─'.repeat(50)}${colors.reset}\n`);
    }
  }
  
  console.log(`${colors.fg.green}${colors.bright}Генерация завершена!${colors.reset}`);
}

// Run the demo
runDemo().catch(error => {
  console.error(`${colors.fg.red}${colors.bright}Ошибка выполнения: ${error.message}${colors.reset}`);
}); 