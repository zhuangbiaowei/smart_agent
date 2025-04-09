module SmartAgent
  class Tool
    attr_accessor :context, :tool_proc

    def initialize(name)
      SmartAgent.logger.info "Create tool's name is #{name}"
      @name = name
      @context = ToolContext.new(self)
    end

    def call(params)
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

      def define(name, &block)
        tool = Tool.new(name)
        tools[name] = tool
        tool.context.instance_eval(&block)
      end

      def find_tool(name)
        tools[name]
      end
    end
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

    def tool_proc(&block)
      @proc = block
    end
  end
end
