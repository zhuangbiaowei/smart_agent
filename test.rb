require "uri"
require "json"
require "net/http"
require "../smart_prompt/lib/smart_prompt"
require "./lib/smart_agent"

engine = SmartAgent::Engine.new("./config/agent.yml")

SmartAgent.define :smart_bot do
  #user_question = params[:text]
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
  #params[:text] = user_question
  #result = call_worker(:summary, params, with_tools: false, with_history: true)
  if result != true
    result.response
  else
    result
  end
end

SmartAgent::Tool.define :get_weather do
  desc "Get weather of an location, the user shoud supply a location first"
  param_define :location, "City or More Specific Address", :string
  param_define :date, "Specific Date or Today or Tomorrow", :string
  # Call the Weather API
  tool_proc do
    "Sunny 10 ℃ ~ 20 ℃"
  end
end

SmartAgent::Tool.define :search do
  desc "Calling Google Search by keywords to get results"
  param_define :q, "Search Keywords", :string
  tool_proc do
    url = URI("https://google.serper.dev/search")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["X-API-KEY"] = ENV["SERPER_API_KEY"]
    request["Content-Type"] = "application/json"
    request.body = JSON.dump({
      "q": input_params["q"],
    })

    response = https.request(request)
    response.read_body
  end
end

SmartAgent::Tool.define :get_code do
  desc "Call the LLM to generate a Ruby function with the input details"
  param_define :name, "ruby function name", :string
  param_define :description, "ruby function description", :string
  param_define :input_params_type, "define of input parameters: (name:type, name:type ... )", :string
  param_define :output_value_type, "type of return value.", :string
  param_define :input_params, "input parameters: (value, value ...)", :string
  tool_proc do
    code = call_worker(:get_code, input_params)
    if input_params["input_params"][0] == "(" && input_params["input_params"][-1] == ")"
      code += "\n" + input_params["name"] + input_params["input_params"]
    else
      code += "\n" + input_params["name"] + "(" + input_params["input_params"] + ")"
    end
    "通过生成的代码:\n #{code} \n得到了结果: #{eval(code)}"
  end
end

SmartAgent::MCPClient.define :opendigger do
  type :stdio
  command "node /root/open-digger-mcp-server/dist/index.js"
end

SmartAgent::MCPClient.define :sequentialthinking_tools do
  type :stdio
  command "node /root/mcp-sequentialthinking-tools/dist/index.js"
end
agent = engine.build_agent(:smart_bot, tools: [:get_weather, :search, :get_code], mcp_servers: [:opendigger, :sequentialthinking_tools])
agent.on_reasoning do |reasoning_content|
  print reasoning_content.dig("choices", 0, "delta", "reasoning_content")
  print "\n" if reasoning_content.dig("choices", 0, "finish_reason") == "stop"
end

agent.on_content do |content|
  print content.dig("choices", 0, "delta", "content")
  print "\n" if content.dig("choices", 0, "finish_reason") == "stop"
end

agent.on_tool_call do |msg|
  puts msg
end

#agent.please("请用中文回答，明天上海的天气。")
#SmartAgent.prompt_engine.clear_history_messages
#agent.please("借助opendigger工具帮我查询并详细列出GitHub上的Vue项目的从2023年1月到2024年12月的OpenRank指标变化")
#SmartAgent.prompt_engine.clear_history_messages
agent.please("请搜索最近关于x.com和马斯克的新闻报道")
#SmartAgent.prompt_engine.clear_history_messages
#agent.please("请通过get_code生成Ruby函数计算三角形的面积，底边长132，高为7.6，告诉我面积是多少？")
#SmartAgent.prompt_engine.clear_history_messages
#agent.please("请通过Ruby函数计算从1到10相加的和是多少？")
#SmartAgent.prompt_engine.clear_history_messages
#agent.please("请通过get_code工具生成的Ruby函数计算梯形的面积，上底为105，下底为232，高为13.5，告诉我面积是多少？")
#SmartAgent.prompt_engine.clear_history_messages
#agent.please("请使用sequentialthinking工具帮我设计一个高效的远程团队会议系统。请从基本需求分析开始，逐步深入思考，用中文回答。")
