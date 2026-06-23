require "json"

module SmartAgent
  class Result
    def initialize(response)
      #SmartAgent.logger.info("response is:" + response.to_s)
      @response = response
    end

    def call_tools
      if @response.class == String
        return false
      else
        tool_calls = normalized_tool_calls
        return false if tool_calls.empty?

        return tool_calls
      end
    end

    def content
      if @response.class == Hash
        @response.dig("choices", 0, "message", "content")
      else
        @response
      end
    end

    def response
      @response
    end

    private

    def normalized_tool_calls
      tool_calls = openai_tool_calls
      return tool_calls if tool_calls && !tool_calls.empty?

      tool_use_blocks.map { |block| normalize_tool_use(block) }.compact
    end

    def openai_tool_calls
      @response.dig("choices", 0, "message", "tool_calls")
    end

    def tool_use_blocks
      content_blocks.select { |block| block["type"] == "tool_use" }
    end

    def content_blocks
      blocks = []
      collect_content_blocks(@response, blocks)
      blocks.select { |block| block.is_a?(Hash) }
    end

    def collect_content_blocks(value, blocks)
      case value
      when Hash
        content = value["content"]
        blocks.concat(content) if content.is_a?(Array)
        value.each_value { |child| collect_content_blocks(child, blocks) }
      when Array
        value.each { |child| collect_content_blocks(child, blocks) }
      end
    end

    def normalize_tool_use(block)
      name = block["name"]
      return nil unless name

      {
        "id" => block["id"],
        "type" => "function",
        "function" => {
          "name" => name,
          "arguments" => tool_arguments(block["input"]),
        },
      }
    end

    def tool_arguments(input)
      return input if input.is_a?(String)

      JSON.generate(input || {})
    end
  end
end
