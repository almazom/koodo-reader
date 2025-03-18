/**
 * Minimax LLM Provider Implementation
 * 
 * This class implements the LLMProvider interface for the Minimax API.
 */

import axios from 'axios';
import { getApiKey } from '../config/api-keys';
import { 
  LLMProvider, 
  LLMOptions, 
  LLMModelInfo, 
  SummaryResult 
} from '../llm-provider.interface';

export class MinimaxProvider implements LLMProvider {
  private apiKey: string | null;
  private baseUrl: string = 'https://api.minimax.chat/v1/text/chatcompletion_pro';
  private defaultModel: string = 'MiniMax-Text-01';
  private fallbackModel: string = 'DeepSeek-R1';

  constructor() {
    this.apiKey = getApiKey('minimax');
  }

  /**
   * Generate a summary of the provided text using Minimax LLM
   * 
   * @param text The text to summarize
   * @param options Options for the summarization
   * @returns Promise with the summary result
   */
  async generateSummary(text: string, options: LLMOptions): Promise<SummaryResult> {
    if (!this.apiKey) {
      throw new Error('Minimax API key not configured');
    }

    const model = options.model || this.defaultModel;
    const temperature = options.temperature || 0.7;
    const max_tokens = options.max_tokens || 2000;
    const systemMessage = options.prompt?.system_message || 
      'Ты профессиональный литературный аналитик, специализирующийся на создании кратких и содержательных резюме глав книг.';
    
    const userMessage = options.prompt?.user_template
      ? options.prompt.user_template.replace('{{chapter_content}}', text)
      : `Создай краткое резюме (2-3 абзаца) следующего текста: \n\n${text}`;

    try {
      const response = await axios.post(
        this.baseUrl,
        {
          model: model,
          messages: [
            { role: 'system', content: systemMessage },
            { role: 'user', content: userMessage }
          ],
          temperature: temperature,
          max_tokens: max_tokens
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`
          }
        }
      );

      // Extract the relevant information from the response
      const summary = response.data.choices[0].message.content;
      const tokensUsed = response.data.usage.total_tokens;
      const tokensInput = response.data.usage.prompt_tokens;
      const tokensOutput = response.data.usage.completion_tokens;

      return {
        summary,
        tokensUsed,
        tokensInput,
        tokensOutput,
        model
      };
    } catch (error) {
      console.error('Error generating summary with Minimax:', error);
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
    if (!this.apiKey) {
      throw new Error('Minimax API key not configured');
    }

    const model = options?.model || this.defaultModel;
    const temperature = options?.temperature || 0.8;
    const max_tokens = options?.max_tokens || 300;
    
    const systemMessage = 'Ты профессиональный поэт, специализирующийся на создании хайку на русском языке. ' +
      'Хайку - это традиционная японская форма поэзии, состоящая из трех строк. ' +
      'В русской адаптации хайку обычно следует схеме 5-7-5 слогов. ' +
      'Твоя задача - создать красивое, элегантное хайку на русском языке по заданной теме.';
    
    const userMessage = `Напиши хайку на русском языке на тему "${theme}". ` +
      'Следуй традиционной структуре 5-7-5 слогов. ' +
      'Хайку должно вызывать яркие образы и эмоции, связанные с природой и временем года.';

    try {
      const response = await axios.post(
        this.baseUrl,
        {
          model: model,
          messages: [
            { role: 'system', content: systemMessage },
            { role: 'user', content: userMessage }
          ],
          temperature: temperature,
          max_tokens: max_tokens
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`
          }
        }
      );

      // Extract the relevant information from the response
      const haiku = response.data.choices[0].message.content;
      const tokensUsed = response.data.usage.total_tokens;
      const tokensInput = response.data.usage.prompt_tokens;
      const tokensOutput = response.data.usage.completion_tokens;

      return {
        summary: haiku,
        tokensUsed,
        tokensInput,
        tokensOutput,
        model
      };
    } catch (error) {
      console.error('Error generating Russian haiku with Minimax:', error);
      throw error;
    }
  }

  /**
   * Check if the API key is valid
   * 
   * @returns Promise with boolean indicating if the key is valid
   */
  async checkAPIKey(): Promise<boolean> {
    if (!this.apiKey) {
      return false;
    }

    try {
      const response = await axios.post(
        this.baseUrl,
        {
          model: this.defaultModel,
          messages: [
            { role: 'system', content: 'You are a helpful assistant.' },
            { role: 'user', content: 'Hello!' }
          ],
          max_tokens: 10
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`
          }
        }
      );

      return response.status === 200;
    } catch (error) {
      console.error('Error checking Minimax API key:', error);
      return false;
    }
  }

  /**
   * Get information about the LLM model
   * 
   * @returns Model information
   */
  getModelInfo(): LLMModelInfo {
    return {
      name: this.defaultModel,
      provider: 'Minimax',
      capabilities: ['summarization', 'haiku-generation', 'text-generation'],
      contextWindow: 16000,
      maxOutputTokens: 4000
    };
  }

  /**
   * Get a list of available models from this provider
   * 
   * @returns Array of available model names
   */
  getAvailableModels(): string[] {
    return [this.defaultModel, this.fallbackModel];
  }
} 