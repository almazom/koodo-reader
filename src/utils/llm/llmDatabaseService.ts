import DatabaseService from "../storage/databaseService";
import LLMSummary from "../../models/LLMSummary";
import LLMConfig from "../../models/LLMConfig";

// Database store names
const LLM_SUMMARIES_STORE = "llm_summaries";
const LLM_CONFIG_STORE = "llm_config";

/**
 * Service for handling LLM-related database operations
 */
class LLMDatabaseService {
  /**
   * Initialize LLM database stores if they don't exist
   */
  static async initializeStores() {
    try {
      // Create stores if they don't exist
      await DatabaseService.createStore(LLM_SUMMARIES_STORE);
      await DatabaseService.createStore(LLM_CONFIG_STORE);
      console.log("LLM stores initialized successfully");
    } catch (error) {
      console.error("Error initializing LLM stores:", error);
    }
  }

  /**
   * Save a chapter summary to the database
   * @param summary The summary to save
   */
  static async saveSummary(summary: LLMSummary) {
    try {
      await DatabaseService.saveAllRecords([summary], LLM_SUMMARIES_STORE);
    } catch (error) {
      console.error("Error saving summary:", error);
      throw error;
    }
  }

  /**
   * Get all summaries for a specific book
   * @param bookKey The book's unique key
   * @returns Array of summaries
   */
  static async getSummariesForBook(bookKey: string): Promise<LLMSummary[]> {
    try {
      const allSummaries = await DatabaseService.getAllRecords(LLM_SUMMARIES_STORE) as LLMSummary[];
      return allSummaries.filter(summary => summary.bookKey === bookKey);
    } catch (error) {
      console.error("Error getting summaries for book:", error);
      return [];
    }
  }

  /**
   * Get a specific chapter summary
   * @param bookKey The book's unique key
   * @param chapterIndex The chapter index
   * @returns The summary if found, undefined otherwise
   */
  static async getChapterSummary(bookKey: string, chapterIndex: number): Promise<LLMSummary | undefined> {
    try {
      const bookSummaries = await this.getSummariesForBook(bookKey);
      return bookSummaries.find(summary => summary.chapterIndex === chapterIndex);
    } catch (error) {
      console.error("Error getting chapter summary:", error);
      return undefined;
    }
  }

  /**
   * Delete a summary by ID
   * @param id The summary ID
   */
  static async deleteSummary(id: string) {
    try {
      await DatabaseService.deleteRecord(LLM_SUMMARIES_STORE, id);
    } catch (error) {
      console.error("Error deleting summary:", error);
      throw error;
    }
  }

  /**
   * Save an LLM configuration
   * @param config The configuration to save
   */
  static async saveConfig(config: LLMConfig) {
    try {
      // If this config is set as default, unset any existing defaults
      if (config.isDefault) {
        const allConfigs = await this.getAllConfigs();
        for (const existingConfig of allConfigs) {
          if (existingConfig.id !== config.id && existingConfig.isDefault) {
            existingConfig.isDefault = false;
            await DatabaseService.saveAllRecords([existingConfig], LLM_CONFIG_STORE);
          }
        }
      }
      
      await DatabaseService.saveAllRecords([config], LLM_CONFIG_STORE);
    } catch (error) {
      console.error("Error saving LLM config:", error);
      throw error;
    }
  }

  /**
   * Get all LLM configurations
   * @returns Array of configurations
   */
  static async getAllConfigs(): Promise<LLMConfig[]> {
    try {
      return await DatabaseService.getAllRecords(LLM_CONFIG_STORE) as LLMConfig[];
    } catch (error) {
      console.error("Error getting LLM configs:", error);
      return [];
    }
  }

  /**
   * Get the default LLM configuration
   * @returns The default configuration if found, undefined otherwise
   */
  static async getDefaultConfig(): Promise<LLMConfig | undefined> {
    try {
      const allConfigs = await this.getAllConfigs();
      return allConfigs.find(config => config.isDefault);
    } catch (error) {
      console.error("Error getting default LLM config:", error);
      return undefined;
    }
  }

  /**
   * Delete an LLM configuration
   * @param id The configuration ID
   */
  static async deleteConfig(id: string) {
    try {
      await DatabaseService.deleteRecord(LLM_CONFIG_STORE, id);
    } catch (error) {
      console.error("Error deleting LLM config:", error);
      throw error;
    }
  }

  /**
   * Check if a chapter has a summary
   * @param bookKey The book's unique key
   * @param chapterIndex The chapter index
   * @returns True if summary exists, false otherwise
   */
  static async hasChapterSummary(bookKey: string, chapterIndex: number): Promise<boolean> {
    const summary = await this.getChapterSummary(bookKey, chapterIndex);
    return !!summary;
  }
}

export default LLMDatabaseService; 