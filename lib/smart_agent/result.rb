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
        tool_calls = @response.dig("choices", 0, "message", "tool_calls")
        if tool_calls
          unless tool_calls.empty?
            return tool_calls
          else
            return false
          end            
        else
          return false
        end
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
  end
end
