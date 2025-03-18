/**
 * LLM API keys configuration - TEMPLATE FILE
 * 
 * This is a template file that shows the structure of api-keys.ts without including 
 * actual API keys. Copy this file to api-keys.ts and add your API keys.
 * 
 * The api-keys.ts file should NEVER be committed to version control.
 */

// Interface for LLM API keys
export interface LLMApiKeys {
  minimax?: string;
  // Add other LLM providers as needed
  deepseek?: string;
  claude?: string;
  gemini?: string;
}

/**
 * Local development key storage
 * For development environment only
 * IMPORTANT: NEVER commit api-keys.ts with actual API keys to version control!
 */
const developmentKeys: LLMApiKeys = {
  minimax: process.env.MINIMAX_API_KEY || "",
  // Add other LLM provider keys as needed
};

/**
 * Get API key for a specific LLM provider
 * 
 * @param provider The LLM provider (e.g., 'minimax', 'deepseek')
 * @returns The API key or null if not available
 */
export function getApiKey(provider: keyof LLMApiKeys): string | null {
  // In production, get keys from secure storage or environment
  if (process.env.NODE_ENV === 'production') {
    // Use environment variables in production
    switch (provider) {
      case 'minimax':
        return process.env.MINIMAX_API_KEY || null;
      case 'deepseek':
        return process.env.DEEPSEEK_API_KEY || null;
      // Add other providers as needed
      default:
        return null;
    }
  }
  
  // For development, use local keys
  return developmentKeys[provider] || null;
}

/**
 * Check if API key is available for a provider
 * 
 * @param provider The LLM provider
 * @returns True if API key is available
 */
export function hasApiKey(provider: keyof LLMApiKeys): boolean {
  return getApiKey(provider) !== null;
}

/**
 * Set API key for a provider (for user-provided keys)
 * 
 * @param provider The LLM provider
 * @param key The API key
 */
export function setApiKey(provider: keyof LLMApiKeys, key: string): void {
  if (process.env.NODE_ENV === 'production') {
    // In production, store in secure storage (implementation depends on platform)
    console.warn('API key storage needs proper implementation for production');
    // Example: localStorage.setItem(`${provider}_api_key`, encryptKey(key));
  } else {
    // For development
    developmentKeys[provider] = key;
  }
}

// TODO: Add proper key encryption/decryption for secure storage
// This is a placeholder for future implementation
function encryptKey(key: string): string {
  // Implement secure encryption
  return key;
}

function decryptKey(encryptedKey: string): string {
  // Implement secure decryption
  return encryptedKey;
} 