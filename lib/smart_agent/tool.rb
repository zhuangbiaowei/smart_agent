module SmartAgent
  class Tool
    def initialize(name)
      SmartAgent.logger.info "Create tool's name is #{name}"
      @name = name
      @code = self.class.tools[name]
    end

    def call(params)
      @context = ToolContext.new
      @context.input_params = params
      @context.instance_eval(&@code)
    end

    def to_json
      @context = ToolContext.new
      @context.instance_eval(&@code)
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
                 description: "",
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
        tools[name] = block
      end

      def find_tool(name)
        tools[name]
      end
    end
  end

  class ToolContext
    attr_accessor :input_params

    def params
      @params ||= {}
    end

    def param_define(name, description, type)
      params[name] = { description: description, type: type }
    end
  end
end
