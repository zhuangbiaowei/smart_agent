require "mcp"

require File.expand_path("../smart_agent/version", __FILE__)
require File.expand_path("../smart_agent/engine", __FILE__)
require File.expand_path("../smart_agent/tool", __FILE__)
require File.expand_path("../smart_agent/mcp_client", __FILE__)
require File.expand_path("../smart_agent/result", __FILE__)
require File.expand_path("../smart_agent/agent", __FILE__)

module SmartAgent
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class APIError < Error; end
  class CallAgentError < Error; end

  attr_writer :logger

  def self.define(name, &block)
    Agent.define(name, &block)
  end

  def self.create(name, tools: nil, mcp_servers: nil)
    Agent.new(name, tools: tools, mcp_servers: mcp_servers)
  end

  def self.build_agent(name, tools: nil, mcp_servers: nil)
    agent = Agent.new(name, tools: tools, mcp_servers: mcp_servers)
    SmartAgent::Engine.agents[name] = agent
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger
  end

  def self.prompt_engine
    @prompt_engine
  end

  def self.prompt_engine=(engine)
    @prompt_engine = engine
  end
end
