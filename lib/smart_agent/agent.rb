module SmartAgent
  class Agent
    attr_accessor :tools, :servers

    def initialize(name, tools: nil, mcp_servers: nil)
      SmartAgent.logger.info "Create agent's name is #{name}"
      @name = name
      @tools = tools
      @servers = mcp_servers
      @code = self.class.agents[name]
    end

    def on_reasoning(&block)
      @reasoning_event_proc = block
    end

    def on_content(&block)
      @content_event_proc = block
    end

    def on_tool_call(&block)
      @tool_call_proc = block
    end

    def on_event
      if @reasoning_event_proc || @content_event_proc
        return true
      else
        return false
      end
    end

    def processor(name)
      case name
      when :reasoning
        return @reasoning_event_proc
      when :content
        return @content_event_proc
      when :tool
        return @tool_call_proc
      else
        return nil
      end
    end

    def please(prompt)
      context = AgentContext.new(self)
      context.params[:text] = prompt
      return context.instance_eval(&@code)
    end

    class << self
      def agents
        @agents ||= {}
      end

      def define(name, &block)
        agents[name] = block
      end
    end
  end

  class AgentContext
    def initialize(agent)
      @agent = agent
    end

    def call_worker(name, params, with_tools: true, with_history: false)
      SmartAgent.logger.info ("Call Worker name is: #{name}")
      if with_tools
        simple_tools = []
        if @agent.tools
          simple_tools = @agent.tools.map { |tool_name| Tool.find_tool(tool_name).to_json }
        end
        if @agent.servers
          mcp_tools = @agent.servers.map { |mcp_name| MCPClient.new(mcp_name).to_json }
          mcp_tools.each do |tools|
            tools["tools"].each do |tool|
              simple_tools << tool
            end
          end
        end
        params[:tools] = simple_tools
      end
      params[:with_history] = with_history
      ret = nil
      if @agent.on_event
        full_result = {}
        tool_calls = []
        result = SmartAgent.prompt_engine.call_worker_by_stream(name, params) do |chunk, _bytesize|
          if full_result.empty?
            full_result["id"] = chunk["id"]
            full_result["object"] = chunk["object"]
            full_result["created"] = chunk["created"]
            full_result["model"] = chunk["model"]
            full_result["choices"] = [{
              "index" => 0,
              "message" => {
                "role" => "assistant",
                "content" => "",
                "reasoning_content" => "",
                "tool_calls" => [],
              },
            }]
            full_result["usage"] = chunk["usage"]
            full_result["system_fingerprint"] = chunk["system_fingerprint"]
          end
          if chunk.dig("choices", 0, "delta", "reasoning_content")
            full_result["choices"][0]["message"]["reasoning_content"] += chunk.dig("choices", 0, "delta", "reasoning_content")
            @agent.processor(:reasoning).call(chunk) if @agent.processor(:reasoning)
          end
          if chunk.dig("choices", 0, "delta", "content")
            full_result["choices"][0]["message"]["content"] += chunk.dig("choices", 0, "delta", "content")
            @agent.processor(:content).call(chunk) if @agent.processor(:content)
          end
          if chunk_tool_calls = chunk.dig("choices", 0, "delta", "tool_calls")
            chunk_tool_calls.each do |tool_call|
              if tool_calls.size > tool_call["index"]
                tool_calls[tool_call["index"]]["function"]["arguments"] += tool_call["function"]["arguments"]
              else
                tool_calls << tool_call
              end
            end
          end
        end
        full_result["choices"][0]["message"]["tool_calls"] = tool_calls
        result = full_result
      else
        result = SmartAgent.prompt_engine.call_worker(name, params)
      end
      ret = Result.new(result)
      return ret
    end

    def call_tools(result)
      @agent.processor(:tool).call({ :status => :start }) if @agent.processor(:tool)
      SmartAgent.logger.info("call tools: " + result.to_s)
      results = []
      result.call_tools.each do |tool|
        tool_call_id = tool["id"]
        tool_name = tool["function"]["name"].to_sym
        params = JSON.parse(tool["function"]["arguments"])
        if Tool.find_tool(tool_name)
          @agent.processor(:tool).call({ :content => "ToolName is `#{tool_name}`\n" }) if @agent.processor(:tool)
          @agent.processor(:tool).call({ :content => "params is `#{params}`\n" }) if @agent.processor(:tool)
          tool_result = Tool.find_tool(tool_name).call(params)

          SmartAgent.prompt_engine.history_messages << { "role" => "assistant", "content" => "", "tool_calls" => [tool] } #result.response.dig("choices", 0, "message")
          SmartAgent.prompt_engine.history_messages << { "role" => "tool", "tool_call_id" => tool_call_id, "content" => tool_result.to_s.force_encoding("UTF-8") }
          results << tool_result
        end
        if server_name = MCPClient.find_server_by_tool_name(tool_name)
          @agent.processor(:tool).call({ :content => "MCP Server is `#{server_name}`, ToolName is `#{tool_name}`\n" }) if @agent.processor(:tool)
          @agent.processor(:tool).call({ :content => "params is `#{params}`\n" }) if @agent.processor(:tool)
          tool_result = MCPClient.new(server_name).call(tool_name, params)
          SmartAgent.prompt_engine.history_messages << { "role" => "assistant", "content" => "", "tool_calls" => [tool] } # result.response.dig("choices", 0, "message")
          SmartAgent.prompt_engine.history_messages << { "role" => "tool", "tool_call_id" => tool_call_id, "content" => tool_result.to_s }
          results << tool_result
        end
        @agent.processor(:tool).call({ :content => " ... done\n" }) if @agent.processor(:tool)
      end
      @agent.processor(:tool).call({ :status => :end }) if @agent.processor(:tool)
      return results
    end

    def params
      @params ||= {}
    end
  end
end
