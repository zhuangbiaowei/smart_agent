require_relative "../lib/smart_agent/result"

RSpec.describe SmartAgent::Result do
  describe "#call_tools" do
    it "returns OpenAI-style tool_calls unchanged" do
      tool_calls = [
        {
          "id" => "call_123",
          "type" => "function",
          "function" => {
            "name" => "search",
            "arguments" => "{\"q\":\"ruby\"}",
          },
        },
      ]
      response = { "choices" => [{ "message" => { "tool_calls" => tool_calls } }] }

      expect(described_class.new(response).call_tools).to eq(tool_calls)
    end

    it "normalizes Anthropic-style tool_use content blocks" do
      response = {
        "content" => [
          { "type" => "text", "text" => "Let me check." },
          {
            "type" => "tool_use",
            "id" => "toolu_123",
            "name" => "get_weather",
            "input" => { "location" => "Shanghai" },
          },
        ],
      }

      expect(described_class.new(response).call_tools).to eq(
        [
          {
            "id" => "toolu_123",
            "type" => "function",
            "function" => {
              "name" => "get_weather",
              "arguments" => "{\"location\":\"Shanghai\"}",
            },
          },
        ],
      )
    end

    it "scans adapter content arrays under choices message" do
      response = {
        "choices" => [
          {
            "message" => {
              "content" => [
                {
                  "type" => "tool_use",
                  "id" => "toolu_456",
                  "name" => "search",
                  "input" => "{\"q\":\"kimi\"}",
                },
              ],
            },
          },
        ],
      }

      expect(described_class.new(response).call_tools).to eq(
        [
          {
            "id" => "toolu_456",
            "type" => "function",
            "function" => {
              "name" => "search",
              "arguments" => "{\"q\":\"kimi\"}",
            },
          },
        ],
      )
    end

    it "returns false when no tool calls are present" do
      response = { "choices" => [{ "message" => { "content" => "done" } }] }

      expect(described_class.new(response).call_tools).to eq(false)
    end
  end
end
