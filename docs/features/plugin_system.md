# Plugin System

## Overview

The Plugin System in Koodo Reader provides extensibility, allowing third-party functionality to be integrated into the application. This system enables features like custom dictionaries, translation services, text-to-speech engines, and potentially LLM integration.

## Architecture

### Core Components

The plugin system consists of:

1. **Plugin Model**: Data structure defining a plugin
2. **Plugin Management**: Redux actions and reducers for managing plugins
3. **Plugin Integration Points**: Components that utilize plugins
4. **Plugin Utility Functions**: Helper functions for plugin operations

### Plugin Model

Plugins are defined by the `Plugin` class in `src/models/Plugin.ts`:

```tsx
class Plugin {
  sourceName: string;
  id: string;
  name: string;
  icon: string;
  url: string;
  description: string;
  type: string;
  options: string;
  
  constructor(
    sourceName: string,
    id: string,
    name: string,
    icon: string,
    url: string,
    description: string,
    type: string,
    options: string
  ) {
    this.sourceName = sourceName;
    this.id = id;
    this.name = name;
    this.icon = icon;
    this.url = url;
    this.description = description;
    this.type = type;
    this.options = options;
  }
}
```

### Plugin Types

The system supports different types of plugins:

- **Dictionary**: Custom dictionary providers
- **Translation**: Language translation services
- **TTS**: Text-to-speech engines
- **Others**: Extendable for additional types

## Implementation Details

### Plugin Management

Plugins are managed through Redux actions:

```tsx
// Action for fetching plugins
export const handleFetchPlugins = () => {
  return (dispatch: Dispatch) => {
    DatabaseService.getAll("plugin").then((results: any) => {
      dispatch({
        type: FETCH_PLUGINS,
        payload: results,
      });
    });
  };
};

// Action for adding a plugin
export const handleAddPlugin = (plugin: Plugin) => {
  return (dispatch: Dispatch) => {
    DatabaseService.add("plugin", plugin).then(() => {
      dispatch({ type: ADD_PLUGIN, payload: plugin });
    });
  };
};

// Action for deleting a plugin
export const handleDeletePlugin = (key: string) => {
  return (dispatch: Dispatch) => {
    DatabaseService.delete("plugin", key).then(() => {
      dispatch({ type: DELETE_PLUGIN, payload: key });
    });
  };
};
```

### Plugin Storage

Plugins are stored in the application's IndexedDB database through `DatabaseService`:

```tsx
// Example of storing a plugin
DatabaseService.add("plugin", pluginObject);

// Example of retrieving plugins
DatabaseService.getAll("plugin");
```

### Plugin Usage

Components check for and utilize available plugins:

```tsx
// Example of checking for a plugin type
const checkPlugin = (type: string, plugins: Plugin[]) => {
  if (!plugins) return null;
  for (let i = 0; i < plugins.length; i++) {
    if (plugins[i].type === type) {
      return plugins[i];
    }
  }
  return null;
};

// Component usage example
const dictionaryPlugin = checkPlugin("dictionary", this.props.plugins);
if (dictionaryPlugin) {
  // Use the dictionary plugin
  // ...
}
```

### Plugin Integration Points

Plugins are integrated at specific points in the application:

- **Dictionary Lookup**: When looking up selected words
- **Translation**: When translating text
- **TTS**: When using text-to-speech features

Each plugin type has specific integration requirements and interfaces.

## Adding a New Plugin

The process of adding a new plugin involves:

1. **Creating a Plugin Object**:

```tsx
const newPlugin = new Plugin(
  "Source Name",
  "unique-id",
  "Plugin Display Name",
  "icon-url",
  "service-url",
  "Description of the plugin",
  "plugin-type",
  "options-json"
);
```

2. **Registering the Plugin**:

```tsx
// Using Redux action
dispatch(handleAddPlugin(newPlugin));

// Or directly with DatabaseService
DatabaseService.add("plugin", newPlugin);
```

3. **Implementing Integration Logic**:

```tsx
// In a component that uses this plugin type
const plugin = checkPlugin("plugin-type", plugins);
if (plugin) {
  // Integration code specific to this plugin type
  // For example, making API calls to the plugin.url
}
```

## Plugin Configuration

Plugins can be configured through the `options` property, which is a JSON string containing plugin-specific settings:

```tsx
// Example of options for a dictionary plugin
const options = JSON.stringify({
  apiKey: "user-api-key",
  language: "en",
  mode: "simple"
});

// Creating a plugin with these options
const dictionaryPlugin = new Plugin(
  "Dictionary Service",
  "dict-service-1",
  "My Dictionary",
  "icon.png",
  "https://api.dictionary.com",
  "Custom dictionary service",
  "dictionary",
  options
);
```

Components can parse and use these options:

```tsx
const plugin = checkPlugin("dictionary", plugins);
if (plugin) {
  const options = JSON.parse(plugin.options);
  const apiKey = options.apiKey;
  // Use the apiKey in API calls
}
```

## Plugin Communication

Plugins typically communicate through:

1. **URL-based API Calls**: Using the plugin's URL for service requests
2. **Parameter Passing**: Sending data as query parameters or request body
3. **Response Handling**: Processing the response from the plugin service

```tsx
// Example of communication with a dictionary plugin
const lookupWord = async (word: string, plugin: Plugin) => {
  try {
    const options = JSON.parse(plugin.options);
    const response = await fetch(
      `${plugin.url}?word=${encodeURIComponent(word)}&key=${options.apiKey}`
    );
    const data = await response.json();
    return data;
  } catch (error) {
    console.error("Error using dictionary plugin:", error);
    return null;
  }
};
```

## Security Considerations

The plugin system implements several security measures:

- **Origin Validation**: Checking plugin URLs against allowed origins
- **Sandboxed Execution**: Limiting plugin capabilities
- **User Confirmation**: Requiring user approval for plugin installation
- **Data Validation**: Validating data received from plugins

## Extending for LLM Integration

The plugin system can be extended to support LLM integration:

### New Plugin Type

Create a new plugin type for LLM services:

```tsx
// Example of LLM plugin
const llmPlugin = new Plugin(
  "OpenAI",
  "openai-gpt4",
  "GPT-4 Integration",
  "openai-icon.png",
  "https://api.openai.com/v1",
  "Integrates OpenAI's GPT-4 for text summarization and Q&A",
  "llm",
  JSON.stringify({
    apiKey: "", // User would provide their API key
    model: "gpt-4",
    temperature: 0.7,
    maxTokens: 2048
  })
);
```

### Integration Points

Potential integration points for LLM plugins:

1. **Text Selection**: Add LLM options to text selection menu
2. **Chapter Navigation**: Add summarization options to chapter view
3. **Book Information**: Add book-level operations for LLM processing
4. **TTS Enhancement**: Pre-process text with LLM before TTS

### Example LLM Integration

```tsx
// Function to summarize text using LLM plugin
const summarizeText = async (text: string, plugin: Plugin) => {
  try {
    const options = JSON.parse(plugin.options);
    
    const response = await fetch(`${plugin.url}/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${options.apiKey}`
      },
      body: JSON.stringify({
        model: options.model,
        prompt: `Summarize the following text:\n\n${text}`,
        max_tokens: options.maxTokens,
        temperature: options.temperature
      })
    });
    
    const data = await response.json();
    return data.choices[0].text;
  } catch (error) {
    console.error("Error using LLM plugin:", error);
    return null;
  }
};

// Using the LLM plugin in a component
const llmPlugin = checkPlugin("llm", this.props.plugins);
if (llmPlugin) {
  const summary = await summarizeText(chapterText, llmPlugin);
  // Display or process the summary
}
```

## Best Practices for Plugin Development

1. **Clear Documentation**: Document the plugin interface and requirements
2. **Error Handling**: Implement robust error handling for plugin operations
3. **User Configuration**: Allow users to configure plugin behavior
4. **Performance Optimization**: Minimize the impact on app performance
5. **Security First**: Follow security best practices for external communication
6. **Graceful Degradation**: Handle cases where plugins are unavailable

## Future Enhancement Opportunities

- **Plugin Marketplace**: A central repository for discovering and installing plugins
- **Plugin Versioning**: Support for plugin versions and compatibility checks
- **Advanced Configuration UI**: Better interface for configuring plugins
- **Plugin Dependencies**: Allow plugins to depend on other plugins
- **Plugin Events**: Event-based communication between plugins and the app
- **Plugin Permissions**: Granular permission system for plugin capabilities 