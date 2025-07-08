# SmartAgent Framework

[![Ruby Version](https://img.shields.io/badge/Ruby-3.2%2B-red)](https://www.ruby-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Version](https://img.shields.io/badge/Version-0.1.8-green.svg)](./lib/smart_agent/version.rb)

**An intelligent agent framework for Ruby with MCP support, tool calling, and multi-LLM integration**

## 🚀 Overview

SmartAgent is a powerful Ruby framework for building intelligent agents that can interact with various AI models, execute tools, and integrate with external services through the Model Context Protocol (MCP). It provides a declarative DSL for defining agents, tools, and workflows.

## ✨ Key Features

### 🤖 **Intelligent Agent System**
- **Agent Definition**: Create custom agents with specific behaviors and capabilities
- **Event-Driven Architecture**: Handle reasoning, content, and tool call events with custom callbacks
- **Multi-Agent Support**: Build and manage multiple specialized agents

### 🔧 **Tool Integration**
- **Built-in Tools**: Weather queries, web search, code generation, and mathematical calculations
- **Custom Tools**: Easy-to-define tools with parameter validation and type checking
- **Tool Groups**: Organize related tools for better management

### 🌐 **MCP (Model Context Protocol) Support**
- **Multiple MCP Servers**: Connect to various MCP-compatible services
- **Protocol Types**: Support for both STDIO and SSE (Server-Sent Events) connections
- **Service Integration**: OpenDigger, PostgreSQL, geographic services, and more

### 🎯 **Multi-LLM Backend Support**
- **Multiple Providers**: OpenAI, DeepSeek, SiliconFlow, Qwen, Ollama, and more
- **Flexible Configuration**: Easy switching between different AI models
- **Streaming Support**: Real-time response streaming with event callbacks

### 📝 **Advanced Prompt System**
- **Template Engine**: ERB-based templates for dynamic prompt generation
- **Worker System**: Specialized workers for different AI tasks
- **History Management**: Conversation context and memory management

## 📦 Installation

### Prerequisites
- Ruby 3.2.0 or higher
- Bundler gem manager

### Installation
Add this line to your application's Gemfile:

```ruby
gem 'smart_agent'
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install smart_agent
```

### Configuration
1. **Configure LLM providers** in `config/llm_config.yml`:
```yaml
llms:
  deepseek:
    adapter: openai
    url: https://api.deepseek.com
    api_key: ENV["DEEPSEEK_API_KEY"]
    default_model: deepseek-reasoner
  # Add other providers...
```

2. **Set up agent configuration** in `config/agent.yml`:
```yaml
logger_file: "./log/agent.log"
engine_config: "./config/llm_config.yml"
agent_path: "./agents"
tools_path: "./agents/tools"
mcp_path: "./agents/mcps"
```

## 🛠️ Usage

### Basic Agent Creation

```ruby
require 'smart_agent'

# Initialize the engine
engine = SmartAgent::Engine.new("./config/agent.yml")

# Define a smart agent
SmartAgent.define :smart_bot do
  call_tool = true
  while call_tool
    result = call_worker(:smart_bot, params, with_tools: true, with_history: true)
    if result.call_tools
      call_tools(result)
      params[:text] = "please continue"
    else
      call_tool = false
    end
  end
  result.response
end

# Build and configure the agent
agent = engine.build_agent(:smart_bot, 
  tools: [:get_weather, :search, :get_code], 
  mcp_servers: [:opendigger, :postgres]
)

# Add event handlers
agent.on_reasoning do |reasoning_content|
  print reasoning_content.dig("choices", 0, "delta", "reasoning_content")
end

agent.on_content do |content|
  print content.dig("choices", 0, "delta", "content")
end

# Use the agent
response = agent.please("What's the weather like in Shanghai tomorrow?")
puts response
```

### Custom Tool Definition

```ruby
SmartAgent::Tool.define :custom_calculator do
  desc "Perform mathematical calculations"
  param_define :expression, "Mathematical expression to evaluate", :string
  param_define :precision, "Number of decimal places", :integer
  
  tool_proc do
    expression = input_params["expression"]
    precision = input_params["precision"] || 2
    
    begin
      result = eval(expression)
      result.round(precision)
    rescue => e
      "Error: #{e.message}"
    end
  end
end
```

### MCP Server Integration

```ruby
# Define MCP servers
SmartAgent::MCPClient.define :opendigger do
  type :stdio
  command "node /path/to/open-digger-mcp-server/dist/index.js"
end

SmartAgent::MCPClient.define :postgres do
  type :stdio
  command "node /path/to/postgres-mcp-server/dist/index.js postgres://user:pass@localhost/db"
end

SmartAgent::MCPClient.define :web_service do
  type :sse
  url "https://api.example.com/mcp/sse"
end

# Use with agent
agent = engine.build_agent(:research_bot, mcp_servers: [:opendigger, :postgres])
```

### Advanced Features

#### Stream Processing with Events
```ruby
agent.on_reasoning do |chunk|
  # Handle reasoning content in real-time
  print chunk.dig("choices", 0, "delta", "reasoning_content")
end

agent.on_tool_call do |event|
  case event[:status]
  when :start
    puts "🔧 Starting tool execution..."
  when :end
    puts "✅ Tool execution completed"
  else
    print event[:content] if event[:content]
  end
end
```

#### Custom Workers
```ruby
SmartPrompt.define_worker :code_analyzer do
  use "deepseek"
  model "deepseek-chat"
  sys_msg "You are an expert code analyzer."
  
  prompt :analyze_template, {
    code: params[:code],
    language: params[:language]
  }
  
  send_msg
end
```

## 🏗️ Architecture

### Core Components

1. **SmartAgent::Engine**
   - Configuration management
   - Agent lifecycle management
   - Tool and MCP server loading

2. **SmartAgent::Agent**
   - Agent behavior definition
   - Tool calling coordination
   - Event handling system

3. **SmartAgent::Tool**
   - Custom tool definition
   - Parameter validation
   - Function execution

4. **SmartAgent::MCPClient**
   - MCP protocol implementation
   - External service integration
   - Multi-protocol support (STDIO/SSE)

5. **SmartAgent::Result**
   - Response processing
   - Tool call detection
   - Content extraction

### Directory Structure
```
├── lib/smart_agent/          # Core framework code
├── config/                   # Configuration files
├── templates/                # Prompt templates
├── workers/                  # Specialized AI workers
├── agents/                   # Agent definitions (auto-loaded)
├── agents/tools/             # Custom tools (auto-loaded)
└── agents/mcps/              # MCP server definitions (auto-loaded)
```

## 🔧 Configuration

### Supported LLM Providers
- **OpenAI Compatible**: DeepSeek, SiliconFlow, Gitee AI
- **Local Solutions**: Ollama, llama.cpp
- **Cloud Services**: Alibaba Cloud DashScope

### Environment Variables
```bash
export DEEPSEEK_API_KEY="your_deepseek_key"
export OPENAI_API_KEY="your_openai_key"
export SERPER_API_KEY="your_serper_key"  # For web search
```

## 🎯 Use Cases

- **Research Assistants**: Integrate with academic databases and search engines
- **Code Analysis Tools**: Generate, analyze, and execute code dynamically
- **Data Analytics**: Connect to databases and perform complex queries
- **Content Creation**: Multi-modal content generation with tool assistance
- **API Integration**: Bridge different services through MCP protocol

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

### Development Setup
```bash
git clone https://github.com/zhuangbiaowei/smart_agent.git
cd smart_agent
bundle install
ruby test.rb  # Run example tests
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on top of the SmartPrompt framework
- Supports the Model Context Protocol (MCP)
- Integrates with various AI model providers

---

**⭐ Star this repository if you find it useful!**