module SmartAgent
  class MCPClient
    def initialize(name)
      SmartAgent.logger.info "Create mcp server's name is #{name}"
      @name = name
      @code = self.class.servers[name]
      @context = MCPContext.new
      @context.instance_eval(&@code)
      command_path = @context.command_path
      if @context.mcp_type == :stdio
        @client = MCP::StdioClient.new(command_path)
      else
        @client = MCP::SSEClient.new(command_path)
      end
      @client.start
    end

    def to_json
      mcp_server_json = @client.list_tools
      if mcp_server_json
        mcp_server_json["tools"].each do |tool|
          MCPClient.set_server(tool["name"].to_sym, @name)
        end
      end
      convertFormat(mcp_server_json)
    end

    def call(tool_name, params, agent = nil)
      if agent
        agent.processor(:tool).call({ :content => "MCP Server is `#{@name}`, ToolName is `#{tool_name}`\n" }) if agent.processor(:tool)
        agent.processor(:tool).call({ :content => "params is `#{params}`\n" }) if agent.processor(:tool)
      end
      @client.call_method(
        {
          "name": tool_name.to_s,
          "arguments": params,
        }
      )
    end

    def close
      @client.stop
    end

    class << self
      def servers
        @servers ||= {}
      end

      def tool_to_server
        @tool_to_server ||= {}
      end

      def define(name, &block)
        servers[name] = block
        client = MCPClient.new(name)
        client.to_json
      end

      def set_server(tool_name, server_name)
        tool_to_server[tool_name] = server_name
      end

      def find_server_by_tool_name(tool_name)
        tool_to_server[tool_name]
      end
    end
  end

  class MCPContext
    def type(mcp_type)
      @mcp_type = mcp_type
    end

    def mcp_type
      @mcp_type
    end

    def command_path
      @command_path
    end

    def command(path)
      @command_path = path
    end

    def url(url)
      @command_path = url
    end
  end
end
