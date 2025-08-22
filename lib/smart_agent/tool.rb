module SmartAgent
  class Tool
    attr_accessor :context, :tool_proc

    def initialize(name)
      SmartAgent.logger.info "Create tool's name is #{name}"
      @name = name
      @context = ToolContext.new(self)
    end

    def call(params, agent = nil)
      if agent
        agent.processor(:tool).call({ :content => "ToolName is `#{@name}`\n" }) if agent.processor(:tool)
        agent.processor(:tool).call({ :content => "params is `#{params}`\n" }) if agent.processor(:tool)
      end
      @context.input_params = params
      @context.instance_eval(&@context.proc)
    end

    def to_json
      params = @context.params
      properties = params.each_with_object({}) do |(name, details), hash|
        hash[name] = {
          type: details[:type],
          description: details[:description],
        }
      end

      return {
               type: "function",
               function: {
                 name: @name,
                 description: @context.description,
                 parameters: {
                   type: "object",
                   properties: properties,
                   required: params.keys,
                 },
               },
             }
    end

    class << self
      def tools
        @tools ||= {}
      end

      def tool_groups
        @tool_groups ||= {}
      end

      def define(name, &block)
        tool = Tool.new(name)
        tools[name] = tool
        tool.context.instance_eval(&block)
      end

      def define_group(name, &block)
        tool_group = ToolGroup.new(name)
        tool_groups[name] = tool_group
        tool_group.context.instance_eval(&block)
      end

      def find_tool(name)
        tools[name]
      end
    end
  end

  class ToolGroup
  end

  class ToolContext
    attr_accessor :input_params, :description, :proc

    def initialize(tool)
      @tool = tool
    end

    def params
      @params ||= {}
    end

    def param_define(name, description, type)
      params[name] = { description: description, type: type }
    end

    def desc(description)
      @description = description
    end

    def call_worker(name, params)
      params[:with_history] = false
      SmartAgent.prompt_engine.call_worker(name, params)
    end

    def call_tool(name, params = {})
      if Tool.find_tool(name)
        return Tool.find_tool(name).call(params)
      end
      if server_name = MCPClient.find_server_by_tool_name(name)
        return MCPClient.new(server_name).call(name, params)
      end
    end

    def tool_proc(&block)
      @proc = block
    end
  end
end
