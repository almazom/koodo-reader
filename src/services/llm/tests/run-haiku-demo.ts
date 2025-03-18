/**
 * Russian Haiku Generation Demo
 * 
 * This script demonstrates the generation of Russian haikus by directly calling the LLM API.
 * Run with: npx ts-node src/services/llm/tests/run-haiku-demo.ts
 */

import { LLMServiceManager } from '../llm-service-manager';
import { validateRussianHaiku } from './utils/russian-syllable-counter';

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  italic: '\x1b[3m',
  underscore: '\x1b[4m',
  blink: '\x1b[5m',
  reverse: '\x1b[7m',
  hidden: '\x1b[8m',
  
  fg: {
    black: '\x1b[30m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
    white: '\x1b[37m',
    crimson: '\x1b[38m'
  },
  bg: {
    black: '\x1b[40m',
    red: '\x1b[41m',
    green: '\x1b[42m',
    yellow: '\x1b[43m',
    blue: '\x1b[44m',
    magenta: '\x1b[45m',
    cyan: '\x1b[46m',
    white: '\x1b[47m',
    crimson: '\x1b[48m'
  }
};

async function generateHaikus() {
  // Create the LLM service
  const llmService = new LLMServiceManager();
  
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
  
  console.log(`${colors.bright}${colors.bg.blue}${colors.fg.white} Русский Хайку Генератор | Russian Haiku Generator ${colors.reset}\n`);
  
  // Generate haikus for each theme
  for (const theme of themes) {
    try {
      console.log(`${colors.fg.yellow}${colors.bright}Генерация хайку на тему "${theme}"...${colors.reset}`);
      console.log(`${colors.dim}(Generating haiku on the theme of "${theme}")${colors.reset}`);
      
      // Generate the haiku
      const result = await llmService.generateRussianHaiku(theme);
      
      // Validate the haiku structure
      const validation = validateRussianHaiku(result.summary);
      
      // Display the haiku
      console.log(`\n${colors.fg.cyan}${colors.bright}▶ Хайку:${colors.reset}`);
      console.log(`${colors.fg.white}${colors.italic}${result.summary}${colors.reset}`);
      
      // Display validation results
      const validationColor = validation.isValid ? colors.fg.green : colors.fg.red;
      console.log(`\n${validationColor}Структура: ${validation.isValid ? 'Верная ✓' : 'Неверная ✗'} (${validation.lineSyllables.join('-')})${colors.reset}`);
      
      // Display token usage
      console.log(`${colors.fg.magenta}Использовано токенов: ${result.tokensUsed} (вход: ${result.tokensInput}, выход: ${result.tokensOutput})${colors.reset}`);
      console.log(`${colors.fg.blue}Модель: ${result.model}${colors.reset}`);
      
      console.log(`\n${colors.dim}${'─'.repeat(50)}${colors.reset}\n`);
    } catch (error) {
      console.error(`${colors.fg.red}Ошибка при генерации хайку на тему "${theme}": ${error}${colors.reset}`);
    }
  }
  
  console.log(`${colors.fg.green}${colors.bright}Генерация завершена!${colors.reset}`);
}

// Run the demo
generateHaikus().catch(error => {
  console.error(`${colors.fg.red}${colors.bright}Ошибка выполнения: ${error}${colors.reset}`);
}); 