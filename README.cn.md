# SmartAgent 智能代理框架

[![Ruby Version](https://img.shields.io/badge/Ruby-3.2%2B-red)](https://www.ruby-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
[![Version](https://img.shields.io/badge/Version-0.2.6-green.svg)](./lib/smart_agent/version.rb)

**支持MCP协议、工具调用和多LLM集成的Ruby智能代理框架**

## 🚀 概述

SmartAgent 是一个功能强大的 Ruby 框架，用于构建能够与各种AI模型交互、执行工具并通过模型上下文协议(MCP)与外部服务集成的智能代理。它提供了声明式DSL来定义代理、工具和工作流。

## ✨ 核心特性

### 🤖 **智能代理系统**
- **代理定义**：创建具有特定行为和能力的自定义代理
- **事件驱动架构**：通过自定义回调处理推理、内容和工具调用事件
- **多代理支持**：构建和管理多个专业化代理

### 🔧 **工具集成**
- **内置工具**：天气查询、网络搜索、代码生成和数学计算
- **自定义工具**：易于定义的工具，支持参数验证和类型检查
- **工具组**：组织相关工具以便更好管理

### 🌐 **MCP (模型上下文协议) 支持**
- **多MCP服务器**：连接各种MCP兼容服务
- **协议类型**：支持STDIO和SSE（服务器发送事件）连接
- **服务集成**：OpenDigger、PostgreSQL、地理服务等

### 🎯 **多LLM后端支持**
- **多提供商**：OpenAI、DeepSeek、SiliconFlow、Qwen、Ollama等
- **灵活配置**：轻松切换不同AI模型
- **流式支持**：带事件回调的实时响应流

### 📝 **高级提示系统**
- **模板引擎**：基于ERB的动态提示生成模板
- **工作器系统**：针对不同AI任务的专业化工作器
- **历史管理**：对话上下文和记忆管理

## 📦 安装

### 系统要求
- Ruby 3.2.0 或更高版本
- Bundler 包管理器

### 安装
添加到你的 Gemfile：

```ruby
gem 'smart_agent'
```

然后执行：
```bash
$ bundle install
```

或直接安装：
```bash
$ gem install smart_agent
```

### 配置

1. **在 `config/llm_config.yml` 中配置LLM提供商**：
```yaml
llms:
  deepseek:
    adapter: openai
    url: https://api.deepseek.com
    api_key: ENV["DEEPSEEK_API_KEY"]
    default_model: deepseek-reasoner
  # 添加其他提供商...
```

2. **在 `config/agent.yml` 中设置代理配置**：
```yaml
logger_file: "./log/agent.log"
engine_config: "./config/llm_config.yml"
agent_path: "./agents"
tools_path: "./agents/tools"
mcp_path: "./agents/mcps"
```

## 🛠️ 使用方法

### 基础代理创建

```ruby
require 'smart_agent'

# 初始化引擎
engine = SmartAgent::Engine.new("./config/agent.yml")

# 定义智能代理
SmartAgent.define :smart_bot do
  call_tool = true
  while call_tool
    result = call_worker(:smart_bot, params, with_tools: true, with_history: true)
    if result.call_tools
      call_tools(result)
      params[:text] = "请继续"
    else
      call_tool = false
    end
  end
  result.response
end

# 构建和配置代理
agent = engine.build_agent(:smart_bot, 
  tools: [:get_weather, :search, :get_code], 
  mcp_servers: [:opendigger, :postgres]
)

# 添加事件处理器
agent.on_reasoning do |reasoning_content|
  print reasoning_content.dig("choices", 0, "delta", "reasoning_content")
end

agent.on_content do |content|
  print content.dig("choices", 0, "delta", "content")
end

# 使用代理
response = agent.please("明天上海的天气怎么样？")
puts response
```

### 自定义工具定义

```ruby
SmartAgent::Tool.define :custom_calculator do
  desc "执行数学计算"
  param_define :expression, "要计算的数学表达式", :string
  param_define :precision, "小数点后位数", :integer
  
  tool_proc do
    expression = input_params["expression"]
    precision = input_params["precision"] || 2
    
    begin
      result = eval(expression)
      result.round(precision)
    rescue => e
      "错误: #{e.message}"
    end
  end
end
```

### MCP服务器集成

```ruby
# 定义MCP服务器
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

SmartAgent::MCPClient.define :limited_web_service do
  type :sse
  url "https://api.example.com/mcp/sse"
  functions [:search, :fetch]
end

# 与代理一起使用
agent = engine.build_agent(:research_bot, mcp_servers: [:opendigger, :postgres])
```

如果配置了 `functions`，则只会向 agent 暴露列出的 MCP 方法；如果不配置 `functions`，则默认暴露该 MCP 服务的全部方法。

### 高级功能

#### 流处理与事件

```ruby
agent.on_reasoning do |chunk|
  # 实时处理推理内容
  print chunk.dig("choices", 0, "delta", "reasoning_content")
end

agent.on_tool_call do |event|
  case event[:status]
  when :start
    puts "🔧 开始执行工具..."
  when :end
    puts "✅ 工具执行完成"
  else
    print event[:content] if event[:content]
  end
end
```

#### 自定义工作器

```ruby
SmartPrompt.define_worker :code_analyzer do
  use "deepseek"
  model "deepseek-chat"
  sys_msg "你是一个专业的代码分析师。"
  
  prompt :analyze_template, {
    code: params[:code],
    language: params[:language]
  }
  
  send_msg
end
```

## 🏗️ 架构

### 核心组件

1. **SmartAgent::Engine**
   - 配置管理
   - 代理生命周期管理
   - 工具和MCP服务器加载

2. **SmartAgent::Agent**
   - 代理行为定义
   - 工具调用协调
   - 事件处理系统

3. **SmartAgent::Tool**
   - 自定义工具定义
   - 参数验证
   - 函数执行

4. **SmartAgent::MCPClient**
   - MCP协议实现
   - 外部服务集成
   - 多协议支持 (STDIO/SSE)

5. **SmartAgent::Result**
   - 响应处理
   - 工具调用检测
   - 内容提取

### 目录结构
```
├── lib/smart_agent/          # 核心框架代码
├── config/                   # 配置文件
├── templates/                # 提示模板
├── workers/                  # 专业化AI工作器
├── agents/                   # 代理定义（自动加载）
├── agents/tools/             # 自定义工具（自动加载）
└── agents/mcps/              # MCP服务器定义（自动加载）
```

## 🔧 配置

### 支持的LLM提供商
- **OpenAI兼容**：DeepSeek、SiliconFlow、Gitee AI
- **本地解决方案**：Ollama、llama.cpp
- **云服务**：阿里云灵积

### 环境变量
```bash
export DEEPSEEK_API_KEY="your_deepseek_key"
export OPENAI_API_KEY="your_openai_key"
export SERPER_API_KEY="your_serper_key"  # 用于网络搜索
```

## 🎯 使用场景

- **研究助手**：与学术数据库和搜索引擎集成
- **代码分析工具**：动态生成、分析和执行代码
- **数据分析**：连接数据库并执行复杂查询
- **内容创作**：借助工具辅助进行多模态内容生成
- **API集成**：通过MCP协议连接不同服务

## 🤝 贡献

我们欢迎贡献！请：

1. Fork 仓库
2. 创建功能分支
3. 为新功能添加测试
4. 确保所有测试通过
5. 提交拉取请求

### 开发环境设置
```bash
git clone https://github.com/zhuangbiaowei/smart_agent.git
cd smart_agent
bundle install
ruby test.rb  # 运行示例测试
```

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- 基于 SmartPrompt 框架构建
- 支持模型上下文协议 (MCP)
- 集成各种AI模型提供商

---

**⭐ 如果觉得有用，请给这个仓库点个星！**
