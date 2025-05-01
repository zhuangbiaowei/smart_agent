SmartPrompt.define_worker :smart_bot do
  #use "deepseek"
  #model "deepseek-chat"
  use "SiliconFlow"
  model "Qwen/Qwen3-32B"
  #model "Qwen/QwQ-32B"
  #use "gitee"
  #model "Qwen3-8B"
  #model "QwQ-32B"
  #use "ollama"
  #model "qwen3"
  #use "aliyun"
  #model "qwen-plus"
  sys_msg "你是一个聪明的智能助手，能够根据需要调用合适的工具解决用户的问题。"
  prompt :summarize, { text: params[:text] }
  send_msg
end
