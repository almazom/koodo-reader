import { v4 as uuidv4 } from "uuid";

/**
 * Supported LLM providers
 */
export type LLMProvider = 
  | "deepseek_v3"
  | "deepseek_r1"
  | "gwen_25_max"
  | "minimax"
  | "gemini_flash_20";

/**
 * Model for LLM API configuration
 */
export class LLMConfig {
  id: string;
  provider: LLMProvider;
  apiKey: string;
  apiEndpoint?: string;
  isDefault: boolean;
  name: string;
  parameters: {
    temperature: number;
    topP: number;
    maxTokens?: number;
    [key: string]: any;
  };

  /**
   * Constructor for LLMConfig
   * @param options Optional partial properties to initialize
   */
  constructor(options: Partial<LLMConfig> = {}) {
    this.id = options.id || uuidv4();
    this.provider = options.provider || "deepseek_v3";
    this.apiKey = options.apiKey || "";
    this.apiEndpoint = options.apiEndpoint || undefined;
    this.isDefault = options.isDefault || false;
    this.name = options.name || "";
    this.parameters = options.parameters || {
      temperature: 0.7,
      topP: 0.9,
    };
  }

  /**
   * Get default parameters based on provider
   * @param provider LLM provider
   * @returns Default parameters
   */
  static getDefaultParameters(provider: LLMProvider) {
    switch (provider) {
      case "deepseek_v3":
        return {
          temperature: 0.7,
          topP: 0.9,
        };
      case "deepseek_r1":
        return {
          temperature: 0.8,
          topP: 0.9,
        };
      case "gwen_25_max":
        return {
          temperature: 0.7,
          topP: 1.0,
        };
      case "minimax":
        return {
          temperature: 0.5,
          topP: 0.95,
        };
      case "gemini_flash_20":
        return {
          temperature: 0.7,
          topP: 0.95,
        };
      default:
        return {
          temperature: 0.7,
          topP: 0.9,
        };
    }
  }
}

export default LLMConfig; 