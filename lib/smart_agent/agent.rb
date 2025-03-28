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

    def call_worker(name, params, result: nil, with_tools: true)
      if result
        params[:result] = result
      end
      if with_tools
        if @agent.tools
          simple_tools = @agent.tools.map { |tool_name| Tool.new(tool_name).to_json }
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
      ret = nil
      if @agent.on_event && with_tools == false
        SmartAgent.prompt_engine.call_worker_by_stream(name, params) do |chunk, _bytesize|
          if chunk.dig("choices", 0, "delta", "reasoning_content")
            @agent.processor(:reasoning).call(chunk)
          end
          if chunk.dig("choices", 0, "delta", "content")
            @agent.processor(:content).call(chunk)
          end
        end
      else
        result = SmartAgent.prompt_engine.call_worker(name, params)
        ret = Result.new(result)
        return ret
      end
    end

    def call_tools(result)
      @agent.processor(:tool).call({ :status => :start })
      SmartAgent.logger.info("call tools: " + result.to_s)
      results = []
      result.call_tools.each do |tool|
        tool_name = tool["function"]["name"].to_sym
        params = JSON.parse(tool["function"]["arguments"])
        if Tool.find_tool(tool_name)
          @agent.processor(:tool).call({ :content => "ToolName is `#{tool_name}`" })
          results << Tool.new(tool_name).call(params)
        end
        if server_name = MCPClient.find_server_by_tool_name(tool_name)
          @agent.processor(:tool).call({ :content => "MCP Server is `#{server_name}`, ToolName is `#{tool_name}`" })
          results << MCPClient.new(server_name).call(tool_name, params)
        end
        @agent.processor(:tool).call({ :content => " ... done\n" })
      end
      @agent.processor(:tool).call({ :status => :end })
      return results
    end

    def params
      @params ||= {}
    end
  end
end
