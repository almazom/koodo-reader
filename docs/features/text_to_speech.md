# Text-to-Speech Module

## Overview

The Text-to-Speech (TTS) module in Koodo Reader enables users to listen to book content through speech synthesis. It leverages both native browser speech synthesis capabilities and external TTS services through plugins.

## Architecture

The TTS feature is implemented as a React component in the following structure:

```
src/components/textToSpeech/
├── component.tsx       # Main TTS component implementation
├── index.tsx           # Container component connecting to Redux
├── interface.tsx       # TypeScript interfaces for props and state
└── textToSpeech.css    # TTS-specific styles
```

## Implementation Details

### Component Structure

The TTS component is a class-based React component:

```tsx
class TextToSpeech extends React.Component<TextToSpeechProps, TextToSpeechState> {
  nodeList: string[];
  voices: any;
  customVoices: any;
  nativeVoices: any;
  
  constructor(props: TextToSpeechProps) {
    super(props);
    this.state = {
      isSupported: false,
      isAudioOn: false,
      isAddNew: false,
    };
    this.nodeList = [];
    this.voices = [];
    this.customVoices = [];
    this.nativeVoices = [];
  }
  
  // Component methods
}
```

### Core Functionality

#### Voice Initialization

The component checks for browser support and initializes available voices:

```tsx
async componentDidMount() {
  if ("speechSynthesis" in window) {
    this.setState({ isSupported: true });
  }
  
  // Initialize speech synthesis
  const setSpeech = () => {
    return new Promise((resolve) => {
      let synth = window.speechSynthesis;
      let voices = synth.getVoices();
      
      // Process and store available voices
      if (voices.length > 0) {
        resolve(voices);
      } else {
        // Handle the case where voices aren't loaded yet
        synth.onvoiceschanged = () => {
          voices = synth.getVoices();
          resolve(voices);
        };
      }
    });
  };
  
  // Get available voices and store them
  this.nativeVoices = await setSpeech();
  this.customVoices = await getAllVoices();
}
```

#### Text Extraction

The component extracts text from the current reading position:

```tsx
handleGetText = async () => {
  // Get text from the current chapter/position
  let nodeList = await TTSUtil.getNodesFromLocation(
    this.props.currentBook.key,
    this.props.htmlBook,
    this.props.locations
  );
  this.nodeList = nodeList;
  return nodeList;
};
```

#### Speech Synthesis

The component provides multiple methods for speech synthesis:

1. **Native Browser TTS**:

```tsx
handleSystemSpeech = async (index, voiceIndex, speed) => {
  // Cancel any ongoing speech
  window.speechSynthesis.cancel();
  
  // Create utterance with selected text
  const utterance = new SpeechSynthesisUtterance(this.nodeList[index]);
  
  // Apply voice and speed settings
  utterance.voice = this.nativeVoices[voiceIndex];
  utterance.rate = speed;
  
  // Set up continuation to next text section
  utterance.onend = () => {
    if (index < this.nodeList.length - 1) {
      // Continue to next section
      this.handleSystemSpeech(index + 1, voiceIndex, speed);
    } else {
      // End of text reached
      this.setState({ isAudioOn: false });
    }
  };
  
  // Start speaking
  window.speechSynthesis.speak(utterance);
};
```

2. **Custom TTS through Plugins**:

```tsx
handleSpeech = async (index, voiceIndex, speed) => {
  // Implementation for custom TTS through plugins
  // This uses external TTS services configured by plugins
};
```

#### User Interface Controls

The component renders controls for TTS operation:

```tsx
render() {
  return (
    <div className="speech-setting">
      {/* Voice selection controls */}
      {/* Speed controls */}
      {/* Play/pause buttons */}
      {/* Plugin integration */}
    </div>
  );
}
```

## Integration Points

### Redux Integration

The TTS component connects to Redux for:

- Current book information
- HTML content access
- Current reading location
- Plugin management

```tsx
const mapStateToProps = (state: stateType) => {
  return {
    currentBook: state.book.currentBook,
    htmlBook: state.reader.htmlBook,
    locations: state.progressPanel.locations,
    isReading: state.book.isReading,
    plugins: state.manager.plugins,
  };
};
```

### Utility Integration

The TTS component leverages several utilities:

- **TTSUtil**: Specialized utility for TTS operations
- **ConfigService**: Configuration management
- **DatabaseService**: Persistence for TTS settings

### Plugin System

The TTS feature supports external TTS services through the plugin system:

```tsx
// Check for TTS plugins
const ttsPlugin = checkPlugin("tts", this.props.plugins);
if (ttsPlugin) {
  // Use plugin for TTS functionality
}
```

## Configuration and Settings

The TTS feature supports configuration for:

- Voice selection (system voices and plugin-provided voices)
- Speech rate/speed
- Auto-continue to next section
- Default settings persistence

## User Experience

### Controls

- **Play/Pause**: Start or pause speech synthesis
- **Voice Selection**: Choose from available system voices or plugin voices
- **Speed Control**: Adjust the speech rate
- **Section Navigation**: Move between text sections

### Integration with Reading

- Synchronizes with current reading position
- Updates as the user navigates through the book
- Can highlight text as it's being read (when supported)

## Limitations and Challenges

- **Browser Support**: Speech synthesis support varies across browsers
- **Voice Quality**: System voices may have limited quality compared to specialized TTS services
- **Language Support**: Limited language options in native browser implementations
- **Performance**: Processing large text sections can impact performance

## Future Enhancement Opportunities

- **Improved Voice Quality**: Integration with more advanced TTS services
- **Better Text Processing**: Enhanced text normalization for difficult content
- **Word Highlighting**: Synchronized highlighting of words being spoken
- **Advanced Controls**: Pause/resume at specific positions, bookmarking in audio
- **Voice Customization**: More control over voice characteristics
- **Audio Export**: Save synthesized speech as audio files for offline listening

## Relevance to LLM Integration

The existing TTS architecture provides a foundation for podcast generation features:

1. **Text Extraction**: Already implemented for current reading position
2. **Voice Synthesis**: Framework for both native and external TTS services
3. **Plugin System**: Extensibility for integrating advanced TTS services
4. **UI Integration**: Pattern for audio playback controls

This can be extended for LLM-enhanced features by:

- Adding summarization before TTS processing
- Enhancing the plugin system to support LLM services
- Expanding the text extraction to support whole chapters/books
- Adding export functionality for podcast-style output 