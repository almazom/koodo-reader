#!/usr/bin/env node
/**
 * Simple Minimax API Test - Haiku Generator
 * 
 * This is a minimal, direct test of the Minimax API connection
 * that generates a haiku about a given theme.
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

/**
 * Generate a haiku about a theme using Minimax API
 */
async function generateHaiku(theme) {
  console.log(`${colors.cyan}Generating haiku about "${theme}"...${colors.reset}`);
  
  try {
    // Simple request body
    const requestBody = {
      model: MODEL,
      messages: [
        {
          role: "system", 
          content: "You are a poet specialized in creating beautiful haikus. A haiku is a three-line poem with a 5-7-5 syllable pattern."
        },
        {
          role: "user",
          content: `Write a haiku about ${theme}.`
        }
      ],
      temperature: 0.8,
      max_tokens: 100
    };
    
    console.log(`${colors.blue}Sending request to Minimax API...${colors.reset}`);
    
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
    
    // Process response
    if (response.status === 200) {
      // Log the actual response structure to understand format
      console.log(`${colors.yellow}API Response Structure:${colors.reset}`, JSON.stringify(response.data, null, 2));
      
      let haiku;
      let usage = { total_tokens: 0, prompt_tokens: 0, completion_tokens: 0 };
      
      // Handle different response formats
      if (response.data.choices && response.data.choices.length > 0) {
        if (response.data.choices[0].message) {
          haiku = response.data.choices[0].message.content;
        } else if (response.data.choices[0].text) {
          haiku = response.data.choices[0].text;
        } else if (response.data.choices[0].content) {
          haiku = response.data.choices[0].content;
        } else {
          console.log(`${colors.yellow}Unexpected response structure:${colors.reset}`, response.data.choices[0]);
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
      
      // Display results
      console.log(`\n${colors.green}✓ API Connection Successful!${colors.reset}`);
      console.log(`\n${colors.magenta}Generated Content:${colors.reset}`);
      console.log(`${colors.yellow}${haiku}${colors.reset}`);
      
      if (usage.total_tokens > 0) {
        console.log(`\n${colors.blue}Token Usage:${colors.reset}`);
        console.log(`${colors.cyan}Total: ${usage.total_tokens}${colors.reset}`);
        console.log(`${colors.cyan}Prompt: ${usage.prompt_tokens}${colors.reset}`);
        console.log(`${colors.cyan}Completion: ${usage.completion_tokens}${colors.reset}`);
      }
      
      return {
        success: true,
        content: haiku,
        usage
      };
    } else {
      throw new Error(`Invalid response status: ${response.status}`);
    }
  } catch (error) {
    console.error(`${colors.red}Error connecting to Minimax API:${colors.reset}`, error.message);
    if (error.response) {
      console.error(`${colors.red}Status:${colors.reset}`, error.response.status);
      console.error(`${colors.red}Data:${colors.reset}`, JSON.stringify(error.response.data, null, 2));
    }
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
  console.log(`${colors.magenta}=== MINIMAX API CONNECTION TEST ===${colors.reset}\n`);
  
  // Test themes
  const themes = ["spring", "ocean", "mountain", "sunset"];
  
  // Generate a haiku for the first theme
  const result = await generateHaiku(themes[0]);
  
  if (result.success) {
    console.log(`\n${colors.green}Test completed successfully!${colors.reset}`);
  } else {
    console.log(`\n${colors.red}Test failed.${colors.reset}`);
    process.exit(1);
  }
}

// Run the main function
main().catch(console.error); 