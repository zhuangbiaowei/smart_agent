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

    def name
      @name
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
      SmartAgent.logger.info("Call Worker name is: #{name}")
      SmartAgent.logger.info("Call Worker params is: #{params}")
      # 记录 session_id，call_tools 写工具结果时需要按 session 路由（HistoryManager 启用时）
      @session_id = params[:session_id]
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
        SmartAgent.prompt_engine.call_worker_by_stream(name, params) do |chunk, _bytesize|
          if chunk.dig("choices", 0, "delta", "reasoning_content")
            @agent.processor(:reasoning).call(chunk) if @agent.processor(:reasoning)
          end
          if chunk.dig("choices", 0, "delta", "content")
            @agent.processor(:content).call(chunk) if @agent.processor(:content)
          end
        end
        result = SmartAgent.prompt_engine.stream_response
      else
        result = SmartAgent.prompt_engine.call_worker(name, params)
      end
      ret = Result.new(result)
      return ret
    end

    def safe_parse(input)
      # 保存原始输入用于调试
      original_input = input.dup

      # 步骤1: 清理输入
      cleaned = input.strip

      # 步骤2: 处理外层引号（如果存在）
      if cleaned.start_with?('"') && cleaned.end_with?('"')
        cleaned = cleaned[1...-1]
      end

      # 步骤3: 反转义双重转义字符
      # 关键：只处理需要反转义的字符，保持JSON合法性
      cleaned = cleaned
        .gsub(/\\"/, '"') # 反转义引号
        .gsub(/\\\\/, '\\')    # 反转义反斜杠
      # 不反转义\n, \t, \r等，因为它们是JSON合法的转义序列

      # 步骤4: 尝试解析
      begin
        return JSON.parse(cleaned)
      rescue JSON::ParserError => e
        # 如果清理后失败，尝试原始输入
        begin
          return JSON.parse(original_input)
        rescue JSON::ParserError
          puts "Failed to parse JSON: #{e.message}"
          puts "Original: #{original_input}"
          puts "Cleaned: #{cleaned}"
          # 返回原始字符串以便后续处理
          return original_input
        end
      end
    end

    def call_tools(result, calls: nil)
      @agent.processor(:tool).call({ :status => :start }) if @agent.processor(:tool)
      SmartAgent.logger.info("call tools: " + result.to_s)
      results = []
      completed_calls = []
      completed_messages = []
      # DeepSeek thinking 模式要求带 tool_calls 的 assistant 消息回传 reasoning_content，否则 400
      reasoning = begin
        result.response.dig("choices", 0, "message", "reasoning_content")
      rescue StandardError
        nil
      end
      # 调用方可传入 calls: 覆盖本次要执行的工具调用集合（如截断 / DSML 兑底解析后的结果）
      source = calls || result.call_tools
      (source || []).each do |tool|
        tool_call_id = tool["id"]
        tool_name = tool["function"]["name"].to_sym
        params = safe_parse(tool["function"]["arguments"])
        if Tool.find_tool(tool_name)
          tool_result = Tool.find_tool(tool_name).call(params, @agent)
          if tool_result
            @agent.processor(:tool).call({ :content => tool_result }) if @agent.processor(:tool)
            completed_calls << tool
            completed_messages << { "role" => "tool", "tool_call_id" => tool_call_id, "content" => tool_result.to_s.force_encoding("UTF-8") }
            results << tool_result
          end
        end
        if server_name = MCPClient.find_server_by_tool_name(tool_name)
          tool_result = MCPClient.new(server_name).call(tool_name, params, @agent)
          if tool_result
            @agent.processor(:tool).call({ :content => tool_result }) if @agent.processor(:tool)
            completed_calls << tool
            completed_messages << { "role" => "tool", "tool_call_id" => tool_call_id, "content" => tool_result.to_s }
            results << tool_result
          end
        end
        @agent.processor(:tool).call({ :content => " ... done\n" }) if @agent.processor(:tool)
      end
      @agent.processor(:tool).call({ :status => :end }) if @agent.processor(:tool)
      return results
    ensure
      # 每轮写一条 assistant 消息（含全部 tool_calls），而不是每个工具各写一条，
      # 避免交错产生 assistant/tool/assistant/tool 序列；被中断时也保留已完成部分。
      if completed_calls && completed_calls.any?
        message = { "role" => "assistant", "content" => "", "tool_calls" => completed_calls }
        message["reasoning_content"] = reasoning if reasoning
        append_history_message(message)
        completed_messages.each { |m| append_history_message(m) }
      end
    end

    # 写历史：HistoryManager 可用时按 session 路由（否则工具结果写全局、读 session 会失忆），
    # 不可用时回退到全局数组（与旧行为一致）。
    def append_history_message(message)
      engine = SmartAgent.prompt_engine
      if engine.respond_to?(:history_manager) && engine.history_manager && @session_id
        engine.history_manager.add_message(@session_id, message)
      elsif engine.respond_to?(:history_messages)
        engine.history_messages << message
      end
    end

    def call_tool(name, params = {})
      if Tool.find_tool(name)
        return Tool.find_tool(name).call(params, @agent)
      end
      if server_name = MCPClient.find_server_by_tool_name(name)
        return MCPClient.new(server_name).call(name, params, @agent)
      end
    end

    def params
      @params ||= {}
    end
  end
end
