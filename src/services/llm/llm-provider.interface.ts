/**
 * LLM Provider Interface
 * 
 * This interface defines the contract for LLM providers that will be used
 * in the Koodo Reader LLM integration.
 */

export interface LLMOptions {
  model?: string;
  prompt?: any;
  temperature?: number;
  max_tokens?: number;
  language?: string;
}

export interface LLMModelInfo {
  name: string;
  provider: string;
  capabilities: string[];
  contextWindow: number;
  maxOutputTokens: number;
}

export interface SummaryResult {
  summary: string;
  tokensUsed: number;
  tokensInput: number;
  tokensOutput: number;
  model: string;
  usedFallback?: boolean;
  originalModel?: string;
  fallbackModel?: string;
}

export interface LLMProvider {
  /**
   * Generate a summary of the provided text
   * 
   * @param text The text to summarize
   * @param options Options for the summarization
   * @returns Promise with the summary result
   */
  generateSummary(text: string, options: LLMOptions): Promise<SummaryResult>;
  
  /**
   * Generate a haiku in Russian based on a theme
   * 
   * @param theme The theme for the haiku
   * @param options Options for haiku generation
   * @returns Promise with the generated haiku
   */
  generateRussianHaiku(theme: string, options?: LLMOptions): Promise<SummaryResult>;
  
  /**
   * Check if the API key is valid
   * 
   * @returns Promise with boolean indicating if the key is valid
   */
  checkAPIKey(): Promise<boolean>;
  
  /**
   * Get information about the LLM model
   * 
   * @returns Model information
   */
  getModelInfo(): LLMModelInfo;
  
  /**
   * Get a list of available models from this provider
   * 
   * @returns Array of available model names
   */
  getAvailableModels(): string[];
} 