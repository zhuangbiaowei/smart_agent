# SmartAgent 智能代理框架

SmartAgent 是一个 Ruby 开发的智能代理框架，支持工具调用和自然语言交互。

## 功能特性

- 支持定义智能代理（SmartAgent）和工具（Tool）
- 内置多种实用工具：
  - 天气查询（get_weather）
  - 数学计算（get_sum）
  - 代码生成与执行（get_code）
- 集成 OpenDigger MCP 服务
- 支持中英文自然语言交互
- 可扩展的工具系统

## 安装

确保已安装 Ruby (>= 2.7) 和 Bundler：

```bash
gem install bundler
```

然后执行：

```bash
bundle install
```

或直接安装 gem：

```bash
gem install smart_agent
```

## 使用示例

### 基础使用

```ruby
require 'smart_agent'

agent = SmartAgent.build_agent(:smart_bot, tools: [:get_code])

# 查询天气
puts agent.please("明天上海的天气")

# 数学计算
puts agent.please("计算130+51的和")

# 代码生成与执行
puts agent.please("请通过Ruby函数计算三角形的面积，底边长132，高为7.6")
```

### 自定义工具

```ruby
SmartAgent::Tool.define :my_tool do
  param_define :param1, "参数说明", :string
  param_define :param2, "另一个参数", :integer
  
  if input_params
    # 工具逻辑
    "处理结果"
  end
end
```

## MCP 集成

支持通过 OpenDigger MCP 服务获取 GitHub 项目指标：

```ruby
SmartAgent::MCPClient.define :opendigger do
  type :stdio
  command "node ~/open-digger-mcp-server/dist/index.js"
end

puts agent.please("查询GitHub上Vue项目的OpenRank指标变化")
```

## 贡献

欢迎提交 Issue 和 Pull Request。

## 许可证

MIT 许可证，详见 LICENSE 文件。