SmartPrompt.define_worker :smart_bot do
  use "deepseek"
  model "deepseek-chat"
  sys_msg "You are a helpful assistant."
  prompt params[:text]
  send_msg
end
