# SmartAgent Framework

SmartAgent is an intelligent agent framework developed in Ruby, supporting tool calling and natural language interaction.

## Features

- Supports defining smart agents (SmartAgent) and tools (Tool)
- Built-in utility tools:
  - Weather query (get_weather)
  - Math calculations (get_sum)
  - Code generation and execution (get_code)
- Integrated with OpenDigger MCP service
- Supports natural language interaction in both English and Chinese
- Extensible tool system

## Installation

Ensure you have Ruby (>= 2.7) and Bundler installed:

```bash
gem install bundler
```

Then run:

```bash
bundle install
```

Or install the gem directly:

```bash
gem install smart_agent
```

## Usage Examples

### Basic Usage

```ruby
require 'smart_agent'

agent = SmartAgent.build_agent(:smart_bot, tools: [:get_code])

# Weather query
puts agent.please("What's the weather in Shanghai tomorrow?")

# Math calculation
puts agent.please("Calculate the sum of 130 and 51")

# Code generation and execution
puts agent.please("Calculate the area of a triangle with base 132 and height 7.6 using a Ruby function")
```

### Custom Tools

```ruby
SmartAgent::Tool.define :my_tool do
  param_define :param1, "Parameter description", :string
  param_define :param2, "Another parameter", :integer
  
  if input_params
    # Tool logic
    "Processing result"
  end
end
```

## MCP Integration

Supports getting GitHub project metrics via OpenDigger MCP service:

```ruby

SmartAgent::MCPClient.define :opendigger do
  type :stdio
  command "node ~/open-digger-mcp-server/dist/index.js"
end

puts agent.please("Query OpenRank metrics changes for Vue project on GitHub")
```

## Contributing

Issues and pull requests are welcome.

## License

MIT License. See LICENSE file for details.