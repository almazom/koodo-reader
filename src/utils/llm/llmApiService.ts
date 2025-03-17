import LLMConfig, { LLMProvider } from "../../models/LLMConfig";
import LLMDatabaseService from "./llmDatabaseService";
import axios from "axios";

/**
 * Service for handling LLM API calls
 */
class LLMApiService {
  /**
   * Generate a chapter summary using the configured LLM provider
   * @param bookTitle Book title for context
   * @param chapterTitle Chapter title
   * @param chapterContent Chapter text content
   * @param config LLM configuration to use (optional - will use default if not provided)
   * @returns Generated summary text
   */
  static async generateSummary(
    bookTitle: string,
    chapterTitle: string,
    chapterContent: string,
    config?: LLMConfig
  ): Promise<string> {
    try {
      // If no config provided, get the default
      if (!config) {
        config = await LLMDatabaseService.getDefaultConfig();
        if (!config) {
          throw new Error("No default LLM configuration found");
        }
      }

      // Create the prompt based on the provider
      const prompt = this.createSummaryPrompt(
        bookTitle,
        chapterTitle,
        chapterContent,
        config.provider
      );

      // Call the appropriate provider API
      const response = await this.callLLMApi(prompt, config);
      
      return response;
    } catch (error) {
      console.error("Error generating summary:", error);
      throw error;
    }
  }

  /**
   * Create a summary prompt based on the provider
   * @param bookTitle Book title
   * @param chapterTitle Chapter title
   * @param chapterContent Chapter content
   * @param provider LLM provider
   * @returns Formatted prompt
   */
  private static createSummaryPrompt(
    bookTitle: string,
    chapterTitle: string,
    chapterContent: string,
    provider: LLMProvider
  ): string {
    // Base prompt template
    const basePrompt = `Task: Summarize the following chapter from "${bookTitle}".

Chapter Title: ${chapterTitle}

Chapter Content:
${chapterContent}

Instructions:
1. Create a concise summary that captures the main ideas, key concepts, and important points from this chapter.
2. Focus on philosophical concepts and their relationships.
3. Include any important terminology defined in this chapter.
4. Maintain factual accuracy and do not introduce information not present in the text.
5. Format the summary in clear paragraphs.

Summary:`;

    // Provider-specific adjustments if needed
    switch (provider) {
      case "deepseek_v3":
      case "deepseek_r1":
      case "gwen_25_max":
      case "minimax":
      case "gemini_flash_20":
      default:
        return basePrompt;
    }
  }

  /**
   * Call the LLM API based on the provider configuration
   * @param prompt The prompt to send
   * @param config LLM configuration
   * @returns Generated text response
   */
  private static async callLLMApi(
    prompt: string,
    config: LLMConfig
  ): Promise<string> {
    try {
      switch (config.provider) {
        case "deepseek_v3":
          return await this.callDeepSeekV3(prompt, config);
        case "deepseek_r1":
          return await this.callDeepSeekR1(prompt, config);
        case "gwen_25_max":
          return await this.callGwen(prompt, config);
        case "minimax":
          return await this.callMinimax(prompt, config);
        case "gemini_flash_20":
          return await this.callGemini(prompt, config);
        default:
          throw new Error(`Unsupported provider: ${config.provider}`);
      }
    } catch (error) {
      console.error(`Error calling ${config.provider} API:`, error);
      throw error;
    }
  }

  /**
   * Call DeepSeek V3 API
   */
  private static async callDeepSeekV3(
    prompt: string,
    config: LLMConfig
  ): Promise<string> {
    // Use config.apiEndpoint if provided, otherwise use default endpoint
    const apiEndpoint = config.apiEndpoint || "https://api.deepseek.com/v3/chat/completions";
    
    try {
      const response = await axios.post(
        apiEndpoint,
        {
          model: "deepseek-v3",
          messages: [{ role: "user", content: prompt }],
          temperature: config.parameters.temperature,
          top_p: config.parameters.topP,
          max_tokens: config.parameters.maxTokens || 1024,
        },
        {
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${config.apiKey}`
          }
        }
      );
      
      // Extract and return the text from the response
      return response.data.choices[0].message.content;
    } catch (error) {
      console.error("Error calling DeepSeek V3 API:", error);
      throw error;
    }
  }
  
  /**
   * Call DeepSeek R1 API
   */
  private static async callDeepSeekR1(
    prompt: string,
    config: LLMConfig
  ): Promise<string> {
    // Implementation similar to DeepSeek V3, adjusted for R1 model
    const apiEndpoint = config.apiEndpoint || "https://api.deepseek.com/v1/chat/completions";
    
    try {
      const response = await axios.post(
        apiEndpoint,
        {
          model: "deepseek-r1",
          messages: [{ role: "user", content: prompt }],
          temperature: config.parameters.temperature,
          top_p: config.parameters.topP,
          max_tokens: config.parameters.maxTokens || 1024,
        },
        {
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${config.apiKey}`
          }
        }
      );
      
      return response.data.choices[0].message.content;
    } catch (error) {
      console.error("Error calling DeepSeek R1 API:", error);
      throw error;
    }
  }
  
  /**
   * Call Gwen API
   */
  private static async callGwen(
    prompt: string,
    config: LLMConfig
  ): Promise<string> {
    // Basic implementation - would need to be adjusted for actual Gwen API
    const apiEndpoint = config.apiEndpoint || "https://api.gwen.example/v1/completions";
    
    try {
      const response = await axios.post(
        apiEndpoint,
        {
          model: "gwen-2.5-max",
          prompt: prompt,
          temperature: config.parameters.temperature,
          top_p: config.parameters.topP,
          max_tokens: config.parameters.maxTokens || 1024,
        },
        {
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${config.apiKey}`
          }
        }
      );
      
      return response.data.choices[0].text;
    } catch (error) {
      console.error("Error calling Gwen API:", error);
      throw error;
    }
  }
  
  /**
   * Call Minimax API
   */
  private static async callMinimax(
    prompt: string,
    config: LLMConfig
  ): Promise<string> {
    // Basic implementation - would need to be adjusted for actual Minimax API
    const apiEndpoint = config.apiEndpoint || "https://api.minimax.example/v1/completions";
    
    try {
      const response = await axios.post(
        apiEndpoint,
        {
          model: "minimax-model",
          prompt: prompt,
          temperature: config.parameters.temperature,
          top_p: config.parameters.topP,
          max_tokens: config.parameters.maxTokens || 1024,
        },
        {
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${config.apiKey}`
          }
        }
      );
      
      return response.data.choices[0].text;
    } catch (error) {
      console.error("Error calling Minimax API:", error);
      throw error;
    }
  }
  
  /**
   * Call Gemini API
   */
  private static async callGemini(
    prompt: string,
    config: LLMConfig
  ): Promise<string> {
    // Basic implementation - would need to be adjusted for actual Gemini API
    const apiEndpoint = config.apiEndpoint || "https://generativelanguage.googleapis.com/v1/models/gemini-flash-2.0:generateContent";
    
    try {
      const response = await axios.post(
        `${apiEndpoint}?key=${config.apiKey}`,
        {
          contents: [
            {
              parts: [
                { text: prompt }
              ]
            }
          ],
          generationConfig: {
            temperature: config.parameters.temperature,
            topP: config.parameters.topP,
            maxOutputTokens: config.parameters.maxTokens || 1024,
          }
        },
        {
          headers: {
            "Content-Type": "application/json"
          }
        }
      );
      
      return response.data.candidates[0].content.parts[0].text;
    } catch (error) {
      console.error("Error calling Gemini API:", error);
      throw error;
    }
  }
}

export default LLMApiService; 