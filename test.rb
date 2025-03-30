require "../smart_prompt/lib/smart_prompt"
require "./lib/smart_agent"

SmartAgent.define :smart_bot do
  result = call_worker(:smart_bot, params, with_tools: true)
  if result.call_tools
    tool_result = call_tools(result)
    result = call_worker(:summary, params, result: tool_result.to_s, with_tools: false)
  end
  if result != true
    result.response
  else
    result
  end
end

SmartAgent::Tool.define :get_weather do
  param_define :location, "City or More Specific Address", :string
  param_define :date, "Specific Date or Today or Tomorrow", :string
  # Call the Weather API
  if input_params
    "Sunny 10 ℃ ~ 20 ℃"
  end
end

SmartAgent::Tool.define :get_sum do
  param_define :a, "number", :integer
  param_define :b, "number", :integer
  if input_params
    input_params["a"] + input_params["b"]
  end
end

SmartAgent::Tool.define :get_code do
  param_define :name, "ruby function name", :string
  param_define :description, "ruby function description", :string
  param_define :input_params_type, "define of input parameters: (name:type, name:type ... )", :string
  param_define :output_value_type, "type of return value.", :string
  param_define :input_params, "input parameters: (value, value ...)", :string
  if input_params
    code = call_worker(:get_code, input_params)
    if input_params["input_params"][0] == "(" && input_params["input_params"][-1] == ")"
      code += "\n" + input_params["name"] + input_params["input_params"]
    else
      code += "\n" + input_params["name"] + "(" + input_params["input_params"] + ")"
    end
    eval(code)
  end
end

SmartAgent::MCPClient.define :opendigger do
  type :stdio
  command "node /root/open-digger-mcp-server/dist/index.js"
end

engine = SmartAgent::Engine.new("./config/agent.yml")

agent = engine.build_agent(:smart_bot, tools: [:get_code])

agent.on_reasoning do |reasoning_content|
  print reasoning_content.dig("choices", 0, "delta", "reasoning_content")
end

agent.on_content do |content|
  print content.dig("choices", 0, "delta", "content")
end

agent.on_tool_call do |msg|
  puts msg
end

puts agent.please("请用中文回答，明天上海的天气。")
puts agent.please("计算130+51的和")
puts agent.please("帮我查询并详细列出GitHub上的Vue项目的从2023年1月到2024年12月的OpenRank指标变化")

puts agent.please("请通过Ruby函数计算三角形的面积，底边长132，高为7.6，告诉我面积是多少？")
puts agent.please("请通过Ruby函数计算从1到10相加的和是多少？")
puts agent.please("请通过Ruby函数计算梯形的面积，上底为105，下底为232，高为13.5，告诉我面积是多少？")
