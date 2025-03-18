/**
 * Simple test for Minimax API connectivity
 */

const axios = require('axios');

// API configuration
const API_KEY = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJHcm91cE5hbWUiOiJBbG1heiBCaWtjaHVyaW4iLCJVc2VyTmFtZSI6IkFsbWF6IEJpa2NodXJpbiIsIkFjY291bnQiOiIiLCJTdWJqZWN0SUQiOiIxODc5ODU0Njg2MTQ0NTY1NTMxIiwiUGhvbmUiOiIiLCJHcm91cElEIjoiMTg3OTg1NDY4NjEzNjE3NjkyMyIsIlBhZ2VOYW1lIjoiIiwiTWFpbCI6ImFsbWF6b21hbUBnbWFpbC5jb20iLCJDcmVhdGVUaW1lIjoiMjAyNS0wMy0xNCAxOToyODo1MSIsIlRva2VuVHlwZSI6MSwiaXNzIjoibWluaW1heCJ9.CtEgIVQqKs-rZDLufflehcnm6bC-p7ppH072Ymo6-p9kOSV5_LR0Ayog0ogH-ZRYu_lZ6z5ycx2TIEek5se-b41Fq4hkrPwREVIM9lvQ8d0RLC2vYNoldF6ZLhBFwwszW3JHK5YqPmN7U_ljKWtlaPGQKSUlmRUXVI4AYUGZ85by8GmXRBJKohihu7whKi71OILZSBsDKBajC00wsF_uRSirT7rSwc_AQvA48tYI7bqgOP17j6GfWZe_VlggqqJYeiTznSaCdi42FG8SO8bTSMnXeE7UstwXL4XO9scVNNBy0iWYPeAzJfvlMbKeIVK71zzXgb9AMhE3zolJWv7jxQ";
const BASE_URL = "https://api.minimaxi.chat/v1/text/chatcompletion_v2";
const MODEL = "MiniMax-Text-01";

// Test function
async function testMiniMaxAPI() {
  console.log("Testing Minimax API connectivity...");
  console.log(`API Key: ${API_KEY.substring(0, 20)}...${API_KEY.substring(API_KEY.length - 10)}`);
  console.log(`URL: ${BASE_URL}`);
  console.log(`Model: ${MODEL}`);
  console.log("\n--- Sending simple request ---\n");

  try {
    // Simple request body
    const requestBody = {
      model: MODEL,
      messages: [
        {
          role: "system",
          content: "You are a helpful assistant.",
          name: "Assistant"
        },
        {
          role: "user",
          content: "Hello! How are you today?",
          name: "user"
        }
      ],
      temperature: 0.7,
      max_tokens: 100
    };

    console.log("Request body:", JSON.stringify(requestBody, null, 2));

    // Make the API call
    const response = await axios.post(
      BASE_URL,
      requestBody,
      {
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${API_KEY}`,
          "Accept": "application/json"
        }
      }
    );

    console.log("\n--- Response received ---");
    console.log("Status:", response.status);
    console.log("Headers:", JSON.stringify(response.headers, null, 2));
    console.log("Data:", JSON.stringify(response.data, null, 2));

    if (response.data && response.data.choices && response.data.choices.length > 0) {
      console.log("\n--- Assistant response ---");
      console.log(response.data.choices[0].message.content);
    }

    console.log("\n✅ Test completed successfully!");
    return true;
  } catch (error) {
    console.error("\n❌ Error testing API:", error.message);
    
    if (error.response) {
      console.error("Status:", error.response.status);
      console.error("Data:", JSON.stringify(error.response.data, null, 2));
    }
    
    console.error("\nFull error:", error);
    return false;
  }
}

// Run the test
testMiniMaxAPI().then(result => {
  console.log("\nTest result:", result ? "SUCCESS" : "FAILED");
}); 