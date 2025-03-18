# Minimax DeepSeek-R1 Integration

## Overview
DeepSeek-R1 is a powerful reasoning model available through the Minimax API that provides enhanced step-by-step reasoning capabilities. This document outlines the integration details, API schema, and usage examples.

## Key Features
- Step-by-step reasoning capabilities
- Separate `reasoning_content` and `content` fields in responses
- Multi-language support (including Russian)
- Enhanced logical problem-solving abilities

## API Endpoint
```
https://api.minimaxi.chat/v1/text/chatcompletion_v2
```

## Request Schema
```typescript
interface DeepSeekR1Request {
  model: string;          // Always "DeepSeek-R1"
  messages: {
    role: "system" | "user" | "assistant";
    content: string;
  }[];
  temperature?: number;   // Default: 0.7, Range: 0-1
  max_tokens?: number;    // Default: 800
  top_p?: number;        // Default: 0.95
}
```

## Response Schema
```typescript
interface DeepSeekR1Response {
  id: string;
  created: number;
  model: string;
  object: string;
  choices: {
    message: {
      content: string;           // Final, concise answer
      reasoning_content: string; // Step-by-step reasoning process
      role: "assistant";
    };
    finish_reason: string;
  }[];
  usage: {
    total_tokens: number;
    prompt_tokens: number;
    completion_tokens: number;
  };
  base_resp: {
    status_code: number;
    status_msg: string;
  };
  input_sensitive: boolean;
  output_sensitive: boolean;
}
```

## Example Usage

### Basic Request
```typescript
const requestPayload = {
  model: "DeepSeek-R1",
  messages: [
    {
      role: "system",
      content: "You are a logical AI assistant that excels at step-by-step reasoning."
    },
    {
      role: "user",
      content: "If x = 5 and y = 3, what is the value of 2x + 3y?"
    }
  ],
  temperature: 0.1,
  max_tokens: 800,
  top_p: 0.95
};
```

### Example Response
```json
{
  "id": "response-id",
  "created": 1679012345,
  "model": "DeepSeek-R1",
  "choices": [
    {
      "message": {
        "reasoning_content": "Let me solve this step by step:\n1. First, let's calculate 2x\n   * x = 5\n   * 2x = 2 × 5 = 10\n2. Next, let's calculate 3y\n   * y = 3\n   * 3y = 3 × 3 = 9\n3. Finally, add the results\n   * 2x + 3y = 10 + 9 = 19",
        "content": "The value of 2x + 3y is 19.",
        "role": "assistant"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "total_tokens": 150,
    "prompt_tokens": 50,
    "completion_tokens": 100
  }
}
```

## Best Practices

### 1. Temperature Setting
- Use lower temperature (0.1-0.3) for mathematical and logical reasoning tasks
- Use higher temperature (0.7-0.9) for creative or open-ended tasks

### 2. Token Management
- Allocate sufficient tokens (800-1000) to accommodate both reasoning and final answer
- Monitor token usage to optimize costs

### 3. System Prompts
- Be explicit about requiring step-by-step reasoning
- Specify the desired format for both reasoning_content and content fields

## Error Handling

Common error codes and their meanings:

```typescript
interface ErrorResponse {
  error: {
    message: string;
    type: string;
    code: number;
  };
}
```

| Status Code | Description | Resolution |
|------------|-------------|------------|
| 401 | Unauthorized | Check API key |
| 429 | Rate limit exceeded | Implement backoff strategy |
| 500 | Server error | Retry with exponential backoff |

## Testing
Comprehensive test suite available in:
- `src/services/llm/tests/minimax-deepseek-r1.test.ts`
- `src/services/llm/tests/minimax-deepseek-r1-focused.test.ts`

## Related Documentation
- [Minimax API Integration](./minimax_api_integration.md)
- [LLM Testing Framework](./llm_testing_framework.md)

## TODO
- [ ] Add streaming response support
- [ ] Implement retry mechanism with exponential backoff
- [ ] Add response caching for frequently used queries
- [ ] Create TypeScript type definitions for request/response schemas 