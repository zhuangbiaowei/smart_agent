# Smart Agent Framework

[![Ruby Version](https://img.shields.io/badge/Ruby-3.2%2B-red)](https://www.ruby-lang.org)
[![Gem Version](https://img.shields.io/gem/v/smart_agent)](https://rubygems.org/gems/smart_agent)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

An intelligent agent framework built on [smart_prompt](https://github.com/zhuangbiaowei/smart_prompt), featuring DSL definition, function calling and MCP protocol integration.

## Key Features

- **Declarative DSL** - Define agents and workflows using concise Ruby syntax
- **Function Calling** - Seamless integration with LLM capabilities
- **MCP Protocol** - Built-in Model Context Protocol support
- **Task Orchestration** - Coordinate multiple agents for complex tasks
- **Extensible Architecture** - Support custom functions and protocol handlers

## Quick Start

```ruby
require 'smart_agent'

SmartAgent.define :weather_bot do
  function :get_weather do |location|
    # Call weather API
  end

  task "Get Weather Forecast" do
    execute ->(params) {
      location = params[:location]
      { forecast: get_weather(location) }
    }
  end
end

agent = SmartAgent.create(:weather_bot)
puts agent.run_task("Get Weather Forecast", location: "Shanghai")
```

## Installation

Add to your Gemfile:
```ruby
gem 'smart_agent'
```

Then execute:
```bash
bundle install
```

Or install directly:
```bash
gem install smart_agent
```

## Documentation

Full documentation available at: [docs.smartagent.dev](https://docs.smartagent.dev)

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add some amazing feature'`)
4. Push branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

Released under the MIT License. See [LICENSE](LICENSE) for details.