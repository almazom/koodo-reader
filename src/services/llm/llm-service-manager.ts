/**
 * LLM Service Manager
 * 
 * This class manages the LLM providers and handles operations like retries and fallbacks.
 */

import { LLMProvider, LLMOptions, SummaryResult } from './llm-provider.interface';
import { MinimaxProvider } from './providers/minimax-provider';

export interface RetryPolicy {
  maxRetries: number;
  delayMs: number;
  exponentialBackoff: boolean;
}

export interface LLMServiceConfig {
  defaultProvider: string;
  fallbackProviders?: string[];
  retryPolicy?: RetryPolicy;
}

export class LLMServiceManager {
  private providers: Map<string, LLMProvider>;
  private defaultProvider: string;
  private fallbackProviders: string[];
  private retryPolicy: RetryPolicy;

  constructor(config?: LLMServiceConfig) {
    this.providers = new Map();
    
    // Register the Minimax provider by default
    const minimaxProvider = new MinimaxProvider();
    this.providers.set('minimax', minimaxProvider);
    
    // Set configuration values
    this.defaultProvider = config?.defaultProvider || 'minimax';
    this.fallbackProviders = config?.fallbackProviders || [];
    this.retryPolicy = config?.retryPolicy || {
      maxRetries: 3,
      delayMs: 1000,
      exponentialBackoff: true
    };
  }

  /**
   * Register a new LLM provider
   * 
   * @param name Provider name
   * @param provider Provider implementation
   */
  registerProvider(name: string, provider: LLMProvider): void {
    this.providers.set(name.toLowerCase(), provider);
  }

  /**
   * Get a provider by name
   * 
   * @param name Provider name
   * @returns LLM provider or undefined if not found
   */
  getProvider(name: string): LLMProvider | undefined {
    return this.providers.get(name.toLowerCase());
  }

  /**
   * Get all registered provider names
   * 
   * @returns Array of provider names
   */
  getProviderNames(): string[] {
    return Array.from(this.providers.keys());
  }

  /**
   * Set the default provider
   * 
   * @param name Provider name
   * @throws Error if provider not found
   */
  setDefaultProvider(name: string): void {
    if (!this.providers.has(name.toLowerCase())) {
      throw new Error(`Provider ${name} not found`);
    }
    this.defaultProvider = name.toLowerCase();
  }

  /**
   * Generate a summary of the provided text
   * 
   * @param text The text to summarize
   * @param options Options for the summarization
   * @returns Promise with the summary result
   */
  async generateSummary(text: string, options: LLMOptions): Promise<SummaryResult> {
    const providerName = options.model?.split('-')[0]?.toLowerCase() || this.defaultProvider;
    const provider = this.getProvider(providerName);

    if (!provider) {
      throw new Error(`Provider ${providerName} not found`);
    }

    try {
      return await this.executeWithRetry(() => provider.generateSummary(text, options));
    } catch (error) {
      // If there's an error and we have fallback providers, try them
      if (this.fallbackProviders.length > 0) {
        for (const fallbackName of this.fallbackProviders) {
          const fallbackProvider = this.getProvider(fallbackName);
          if (fallbackProvider) {
            try {
              const result = await this.executeWithRetry(() => 
                fallbackProvider.generateSummary(text, options)
              );
              
              // Add fallback information
              return {
                ...result,
                usedFallback: true,
                originalModel: options.model,
                fallbackModel: result.model
              };
            } catch (fallbackError) {
              console.error(`Fallback provider ${fallbackName} failed:`, fallbackError);
              // Continue to next fallback
            }
          }
        }
      }
      
      // If we get here, all providers failed
      throw error;
    }
  }

  /**
   * Generate a haiku in Russian based on a theme
   * 
   * @param theme The theme for the haiku
   * @param options Options for haiku generation
   * @returns Promise with the generated haiku
   */
  async generateRussianHaiku(theme: string, options?: LLMOptions): Promise<SummaryResult> {
    const providerName = options?.model?.split('-')[0]?.toLowerCase() || this.defaultProvider;
    const provider = this.getProvider(providerName);

    if (!provider) {
      throw new Error(`Provider ${providerName} not found`);
    }

    try {
      return await this.executeWithRetry(() => provider.generateRussianHaiku(theme, options));
    } catch (error) {
      // If there's an error and we have fallback providers, try them
      if (this.fallbackProviders.length > 0) {
        for (const fallbackName of this.fallbackProviders) {
          const fallbackProvider = this.getProvider(fallbackName);
          if (fallbackProvider) {
            try {
              const result = await this.executeWithRetry(() => 
                fallbackProvider.generateRussianHaiku(theme, options)
              );
              
              // Add fallback information
              return {
                ...result,
                usedFallback: true,
                originalModel: options?.model,
                fallbackModel: result.model
              };
            } catch (fallbackError) {
              console.error(`Fallback provider ${fallbackName} failed:`, fallbackError);
              // Continue to next fallback
            }
          }
        }
      }
      
      // If we get here, all providers failed
      throw error;
    }
  }

  /**
   * Execute a function with retry logic
   * 
   * @param fn The function to execute
   * @returns Promise with the result
   */
  private async executeWithRetry<T>(fn: () => Promise<T>): Promise<T> {
    let lastError: Error | undefined;
    let delay = this.retryPolicy.delayMs;

    for (let attempt = 0; attempt <= this.retryPolicy.maxRetries; attempt++) {
      try {
        // If not the first attempt, wait before retrying
        if (attempt > 0) {
          await new Promise(resolve => setTimeout(resolve, delay));
          // Increase delay if using exponential backoff
          if (this.retryPolicy.exponentialBackoff) {
            delay *= 2;
          }
        }
        
        return await fn();
      } catch (error) {
        console.error(`Attempt ${attempt + 1}/${this.retryPolicy.maxRetries + 1} failed:`, error);
        lastError = error as Error;
      }
    }

    // If we get here, all attempts failed
    throw lastError || new Error('Operation failed after retries');
  }
} 