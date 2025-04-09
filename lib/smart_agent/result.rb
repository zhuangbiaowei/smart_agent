module SmartAgent
  class Result
    def initialize(response)
      SmartAgent.logger.info("response is:" + response.to_s)
      @response = response
    end

    def call_tools
      if @response.class == String
        return false
      else
        tool_calls = @response.dig("choices", 0, "message", "tool_calls")
        if tool_calls.empty?
          return false
        else
          return tool_calls
        end
      end
    end

    def content
      @response.dig("choices", 0, "message", "content")
    end

    def response
      @response
    end
  end
end
