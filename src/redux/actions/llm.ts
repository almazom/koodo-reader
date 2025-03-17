import * as types from "./actionTypes";
import LLMConfig from "../../models/LLMConfig";
import LLMSummary from "../../models/LLMSummary";
import LLMDatabaseService from "../../utils/llm/llmDatabaseService";

/**
 * Add or update an LLM configuration
 * @param config LLM configuration to add or update
 */
export const addLLMConfig = (config: LLMConfig) => async (dispatch: any) => {
  try {
    // Save to database
    await LLMDatabaseService.saveConfig(config);

    // Dispatch Redux action
    dispatch({
      type: types.ADD_LLM_CONFIG,
      payload: config
    });
  } catch (error) {
    console.error("Error adding LLM config:", error);
  }
};

/**
 * Delete an LLM configuration
 * @param configId ID of the configuration to delete
 */
export const deleteLLMConfig = (configId: string) => async (dispatch: any) => {
  try {
    // Delete from database
    await LLMDatabaseService.deleteConfig(configId);

    // Dispatch Redux action
    dispatch({
      type: types.DELETE_LLM_CONFIG,
      payload: configId
    });
  } catch (error) {
    console.error("Error deleting LLM config:", error);
  }
};

/**
 * Set a configuration as the default
 * @param configId ID of the configuration to set as default
 */
export const setDefaultLLMConfig = (configId: string) => async (dispatch: any) => {
  try {
    // Get all configs
    const configs = await LLMDatabaseService.getAllConfigs();
    
    // Find the config to set as default
    const configToUpdate = configs.find(config => config.id === configId);
    
    if (configToUpdate) {
      // Update config
      configToUpdate.isDefault = true;
      
      // Set all other configs to non-default
      for (const config of configs) {
        if (config.id !== configId && config.isDefault) {
          config.isDefault = false;
          await LLMDatabaseService.saveConfig(config);
        }
      }
      
      // Save updated config
      await LLMDatabaseService.saveConfig(configToUpdate);
      
      // Dispatch Redux action
      dispatch({
        type: types.SET_DEFAULT_LLM_CONFIG,
        payload: configId
      });
    }
  } catch (error) {
    console.error("Error setting default LLM config:", error);
  }
};

/**
 * Add or update an LLM summary
 * @param summary LLM summary to add or update
 */
export const addLLMSummary = (summary: LLMSummary) => async (dispatch: any) => {
  try {
    // Save to database
    await LLMDatabaseService.saveSummary(summary);

    // Dispatch Redux action
    dispatch({
      type: types.ADD_LLM_SUMMARY,
      payload: summary
    });
  } catch (error) {
    console.error("Error adding LLM summary:", error);
  }
};

/**
 * Delete an LLM summary
 * @param summaryId ID of the summary to delete
 */
export const deleteLLMSummary = (summaryId: string) => async (dispatch: any) => {
  try {
    // Delete from database
    await LLMDatabaseService.deleteSummary(summaryId);

    // Dispatch Redux action
    dispatch({
      type: types.DELETE_LLM_SUMMARY,
      payload: summaryId
    });
  } catch (error) {
    console.error("Error deleting LLM summary:", error);
  }
}; 