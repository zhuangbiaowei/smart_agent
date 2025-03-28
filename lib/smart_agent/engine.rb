module SmartAgent
  class Engine
    def initialize(config_file)
      @config_file = config_file
      load_config(config_file)
      SmartAgent.logger.info "Started create the SmartAgent engine."
    end

    def create_dir(filename)
      path = File::path(filename).to_s
      parent_dir = File::dirname(path)
      Dir.mkdir(parent_dir, 0755) unless File.directory?(parent_dir)
    end

    def load_config(config_file)
      begin
        @config_file = config_file
        @config = YAML.load_file(config_file)
        if @config["logger_file"]
          create_dir(@config["logger_file"])
          SmartAgent.logger = Logger.new(@config["logger_file"])
        end
        if engine_config = @config["engine_config"]
          SmartAgent.prompt_engine = SmartPrompt::Engine.new(engine_config)
        else
          SmartAgent.logger.error "SmartPrompt Config file not found: #{ex.message}"
          raise ConfigurationError, "SmartPrompt Config file not found: #{ex.message}"
        end
        load_tools
        load_mcp_server
        load_agents
        SmartAgent.logger.info "Loading configuration from file: #{config_file}"
      rescue Psych::SyntaxError => ex
        SmartAgent.logger.error "YAML syntax error in config file: #{ex.message}"
        raise ConfigurationError, "Invalid YAML syntax in config file: #{ex.message}"
      rescue Errno::ENOENT => ex
        SmartAgent.logger.error "Config file not found: #{ex.message}"
        raise ConfigurationError, "Config file not found: #{ex.message}"
      rescue StandardError => ex
        SmartAgent.logger.error "Error loading configuration: #{ex.message}"
        raise ConfigurationError, "Error loading configuration: #{ex.message}"
      ensure
        SmartAgent.logger.info "Configuration loaded successfully"
      end
    end

    def load_tools
      Dir.glob(File.join(@config["tools_path"], "*.rb")).each do |file|
        require(file)
      end
    end

    def load_mcp_server
      Dir.glob(File.join(@config["mcp_path"], "*.rb")).each do |file|
        require(file)
      end
    end

    def load_agents
      Dir.glob(File.join(@config["agent_path"], "*.rb")).each do |file|
        require(file)
      end
    end

    def build_agent(name, tools: nil, mcp_servers: nil)
      agent = Agent.new(name, tools: tools, mcp_servers: mcp_servers)
      agents[name] = agent
    end

    def agents
      self.class.agents
    end

    def self.agents
      @agents ||= {}
    end
  end
end
