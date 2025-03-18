# Russian Haiku Generator

## Overview

The Russian Haiku Generator is a specialized tool that uses the Minimax API to generate beautiful Russian haikus on various themes. This tool serves as a validation test for our LLM integration into Koodo Reader, demonstrating successful API connectivity and response handling.

## Features

- Integration with Minimax API (MiniMax-Text-01 model)
- Beautiful terminal UI with ANSI color formatting
- Russian syllable counting and pattern analysis
- Support for various themes (seasons, nature, books, etc.)
- Proper error handling and API response validation
- Comprehensive debugging capabilities

## Files

- `run-haiku-demo.js` - Main Russian Haiku Generator script
- `test-minimax-api.js` - Simple API connectivity test script

## Technical Details

### API Integration

The generator connects to the Minimax API at `https://api.minimaxi.chat/v1/text/chatcompletion_v2` and uses proper Bearer token authentication. The implementation includes:

- Correct headers format (`Authorization: Bearer <token>`)
- Proper request body structure with system and user messages
- Complete response parsing and error handling
- Token usage tracking

### Russian Language Support

The generator includes specialized support for Russian language processing:

- Russian vowel detection for syllable counting (а, е, ё, и, о, у, ы, э, ю, я)
- Multi-line text analysis for haiku structure
- Pattern analysis showing syllable distribution (e.g., 5-7-5)

### User Experience

The generator features a rich terminal UI with:

- Color-coded outputs for different types of information
- Unicode box drawing for visual separation between haikus
- Italic formatting for the actual haiku text
- Clear error messages with detailed diagnostics

## Usage

Run the generator with Node.js:

```
node run-haiku-demo.js
```

To test basic API connectivity:

```
node test-minimax-api.js
```

## Example Output

The generator produces beautiful Russian haikus like:

```
Снег ложится тихо,  
Серебристый шепот веток —  
Зимний сон лесов.
```

## Future Improvements

- Add command-line arguments for custom themes
- Implement strict 5-7-5 structure enforcement option
- Add support for saving generated haikus to a file
- Create a simple web UI for the generator
- Integrate with additional LLM providers

## Integration with Koodo Reader

This tool demonstrates our successful API integration that will be used in the chapter summarization feature. The same authentication and request handling patterns will be applied when connecting Koodo Reader to the Minimax API for generating chapter summaries. 