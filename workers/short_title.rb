SmartPrompt.define_worker :short_title do
  use "SiliconFlow"
  model "Qwen/Qwen2.5-7B-Instruct"
  prompt :short_title, {text: params[:text]}
  send_msg
end