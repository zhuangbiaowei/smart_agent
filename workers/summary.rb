SmartPrompt.define_worker :summary do
  use "deepseek"
  model "deepseek-chat"
  sys_msg "You are a helpful assistant."
  prompt :summarize, { text: params[:text], tool_result: params[:result] }
  send_msg
end
