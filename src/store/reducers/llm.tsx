import LLMConfig from "../../models/LLMConfig";
import LLMSummary from "../../models/LLMSummary";

// Initial state
const initialState = {
  configs: [] as LLMConfig[],
  summaries: [] as LLMSummary[],
};

type ActionType = {
  type: string;
  payload: any;
};

// Add action types to this reducer
export const llm = (state = initialState, action: ActionType) => {
  switch (action.type) {
    // LLM Configuration actions
    case "ADD_LLM_CONFIG":
      // Check if config already exists to update
      const existingConfigIndex = state.configs.findIndex(
        (config) => config.id === action.payload.id
      );
      
      if (existingConfigIndex >= 0) {
        // Update existing config
        const updatedConfigs = [...state.configs];
        updatedConfigs[existingConfigIndex] = action.payload;
        return { ...state, configs: updatedConfigs };
      } else {
        // Add new config
        return { ...state, configs: [...state.configs, action.payload] };
      }
    
    case "DELETE_LLM_CONFIG":
      return {
        ...state,
        configs: state.configs.filter(config => config.id !== action.payload)
      };
    
    case "SET_DEFAULT_LLM_CONFIG":
      return {
        ...state,
        configs: state.configs.map(config => ({
          ...config,
          isDefault: config.id === action.payload
        }))
      };
    
    // LLM Summary actions
    case "ADD_LLM_SUMMARY":
      // Check if summary already exists to update
      const existingSummaryIndex = state.summaries.findIndex(
        (summary) => summary.id === action.payload.id
      );
      
      if (existingSummaryIndex >= 0) {
        // Update existing summary
        const updatedSummaries = [...state.summaries];
        updatedSummaries[existingSummaryIndex] = action.payload;
        return { ...state, summaries: updatedSummaries };
      } else {
        // Add new summary
        return { ...state, summaries: [...state.summaries, action.payload] };
      }
    
    case "DELETE_LLM_SUMMARY":
      return {
        ...state,
        summaries: state.summaries.filter(summary => summary.id !== action.payload)
      };
    
    default:
      return state;
  }
}; 