# Smart Agent 智能体框架

[![Ruby 版本](https://img.shields.io/badge/Ruby-3.2%2B-red)](https://www.ruby-lang.org)
[![Gem 版本](https://img.shields.io/gem/v/smart_agent)](https://rubygems.org/gems/smart_agent)
[![许可证](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

基于 [smart_prompt](https://github.com/zhuangbiaowei/smart_prompt) 构建的智能体框架，支持 DSL 定义、函数调用和 MCP 协议集成。

## 核心特性

- **声明式 DSL** - 使用简洁的 Ruby 语法定义智能体和工作流
- **函数调用** - 无缝集成大语言模型能力
- **MCP 协议** - 内置模型上下文协议支持
- **任务编排** - 协调多个智能体完成复杂任务
- **可扩展架构** - 支持自定义函数和协议处理器

## 快速开始

```ruby
require 'smart_agent'

SmartAgent.define :weather_bot do
  function :get_weather do |location|
    # 调用天气API
  end

  task "获取天气预报" do
    execute ->(params) {
      location = params[:location]
      { forecast: get_weather(location) }
    }
  end
end

agent = SmartAgent.create(:weather_bot)
puts agent.run_task("获取天气预报", location: "上海")
```

## 安装

添加到 Gemfile:
```ruby
gem 'smart_agent'
```

然后执行:
```bash
bundle install
```

或直接安装:
```bash
gem install smart_agent
```

## 文档

完整文档请访问: [docs.smartagent.dev](https://docs.smartagent.dev)

## 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交修改 (`git commit -m '添加新特性'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 发起 Pull Request

## 许可证

基于 MIT 许可证发布，详见 [LICENSE](LICENSE)。