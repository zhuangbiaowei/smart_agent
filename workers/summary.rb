SmartPrompt.define_worker :summary do
  use "deepseek"
  model "deepseek-chat"
  #use "SiliconFlow"
  #model "deepseek-ai/DeepSeek-V3"
  #sys_msg "You are a helpful assistant."
  prompt :summarize, { text: params[:text] }
  send_msg
end
